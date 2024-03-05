# frozen_string_literal: true

require_relative 'bolt11/version'
require_relative 'bolt11/bitstring'
require_relative 'bolt11/ln_addr'
require_relative 'bolt11/routing_info'
require_relative 'bolt11/secp256k1'
require 'bigdecimal'
require 'bitcoin'
require 'bech32'

# Bolt11 is a module that provides a method to decode a BOLT #11 invoice.
module Bolt11
  # BOLT #11:
  # The following `multiplier` letters are defined:
  #
  # * `m` (milli): multiply by 0.001
  # * `u` (micro): multiply by 0.000001
  # * `n` (nano): multiply by 0.000000001
  # * `p` (pico): multiply by 0.000000000001
  UNITS = {
    p: 10**12,
    n: 10**9,
    u: 10**6,
    m: 10**3
  }.freeze

  BASE58_PREFIXES = {
    bc: [0, 5],
    tb: [111, 196]
  }.freeze

  module_function

  # Decode a BOLT #11 invoice
  # @param invoice [String] the invoice to decode
  # @param max_length [Integer] the maximum length of the invoice
  # @return [Bolt11::LnAddr] the decoded invoice
  def decode(invoice, max_length: 1024)
    hrp, data_part = Bech32.decode(invoice, max_length)
    raise ArgumentError, 'Invalid invoice: bad bech32 checksum' if hrp.nil?

    # A reader MUST fail if it does not understand the `prefix`.
    raise ArgumentError, "Invalid invoice: does not start with 'ln'" unless hrp.start_with?('ln')

    data_bs = Bitstring.new(data_part)
    raise ArgumentError, 'Invalid invoice: too short to contain a signature' if data_bs.length < 65 * 8

    lnaddr = LnAddr.new
    lnaddr.pubkey = nil
    lnaddr.currency, lnaddr.amount = decode_hrp(hrp)

    # BOLT #11:
    #
    # 1. timestamp: seconds-since-1970 (35 bits, big-endian)
    # 2. zero or more tagged parts
    # 3. signature: Bitcoin-style signature of above (520 bits)
    data_bs = Bitstring.new(data_part[0..data_part.length - 105])
    lnaddr.timestamp = data_bs.read(35).to_i
    # tagged_fields = data_part[7..data_part.length - 105] # ∵ 520 bits == 5 bits * 104
    # need to convert tobytes
    # sigdecoded = Bitstring.new(data_part[105, data_part.length]).to_bytes

    while data_bs.pos < data_bs.length # - 65 * 8
      tag_type = data_bs.read(5).to_i
      tag = Bech32::CHARSET[tag_type]

      data_length = data_bs.read(5).to_i * 32 + data_bs.read(5).to_i
      tag_data = data_bs.read(data_length * 5)
      case tag
      when 's'
        if data_length != 52
          lnaddr.unknown_tags << [tag, tag_data]
          next
        end
        lnaddr.payment_secret = to_hex(tag_data.trim_to_bytes)
      # BOLT #11:
      #
      # * `r` (3): `data_length` variable.  One or more entries
      # containing extra routing information for a private route;
      # there may be more than one `r` field, too.
      #    * `pubkey` (264 bits)
      #    * `short_channel_id` (64 bits)
      #    * `feebase` (32 bits, big-endian)
      #    * `feerate` (32 bits, big-endian)
      #    * `cltv_expiry_delta` (16 bits, big-endian)
      when 'r'
        while tag_data.pos + 264 + 64 + 32 + 32 + 16 < tag_data.length
          route = RoutingInfo.new(
            to_hex(tag_data.read(264).to_bytes),
            tag_data.read(64).to_bytes,
            tag_data.read(32).int,
            tag_data.read(32).int,
            tag_data.read(16).int
          )
          lnaddr.routing_info << route
        end
      # BOLT #11
      #
      # f (9): data_length variable, depending on version.
      # Fallback on-chain address: for Bitcoin, this starts with a 5-bit version
      # and contains a witness program or P2PKH or P2SH address.
      # TODO
      when 'f'
        fallback = parse_fallback(lnaddr, tag_data)
        lnaddr.fallback_addr = fallback unless fallback.nil?
        lnaddr.unknown_tags << [tag, tag_data] if fallback.nil?
      # BOLT #11
      #
      # d (13): data_length variable.
      # Short description of purpose of payment (UTF-8), e.g. '1 cup of coffee' or 'ナンセンス 1杯'
      when 'd'
        lnaddr.short_description = tag_data.trim_to_bytes.pack('C*').force_encoding('utf-8')
      # BOLT #11
      #
      # h (23): data_length 52.
      # 256-bit description of purpose of payment (SHA256).
      # This is used to commit to an associated description that is over 639
      # bytes, but the transport mechanism for the description in that case is
      # transport specific and not defined here.
      when 'h'
        if data_length != 52
          lnaddr.unknown_tags << [tag, tag_data]
          next
        end
        lnaddr.description_hash = to_hex(tag_data.trim_to_bytes)
      # BOLT #11
      #
      # x (6): data_length variable.
      # expiry time in seconds (big-endian). Default is 3600 (1 hour) if not specified.
      when 'x'
        lnaddr.expiry = tag_data.to_i
      # BOLT #11
      #
      # p (1): data_length 52.
      # 256-bit SHA256 payment_hash. Preimage of this provides proof of payment.
      when 'p'
        if data_length != 52
          lnaddr.unknown_tags.push([type, tag_data])
          next
        end
        lnaddr.payment_hash = to_hex(tag_data.trim_to_bytes)
      # BOLT #11
      #
      # n (19): data_length 53.
      # 33-byte public key of the payee node
      when 'n'
        if data_length != 53
          lnaddr.unknown_tags << [tag, tag_data]
          next
        end
        lnaddr.pubkey = tag_data.to_bytes.pack('C*')
      end
    end

    sigdata = Bitstring.new(data_part)
    sigdata.pos = sigdata.length - 65 * 8
    signature = sigdata.read(65 * 8).to_bytes

    # if lnaddr.pubkey.nil?
    #   # TODO: recover pubkey from signature
    # else
    #   # TODO: check signature
    # end

    # BOLT #11:
    #
    # A reader MUST use the `n` field to validate the signature instead of
    # performing signature recovery if a valid `n` field is provided.
    # addr.signature = addr.pubkey.ecdsa_deserialize_compact(sigdecoded[0:64])
    # if not addr.pubkey.ecdsa_verify(bytearray([ord(c) for c in hrp]) + data.tobytes(), addr.signature):
    # raise ValueError('Invalid signature')
    # puts "lnaddr.pubkey: #{lnaddr.pubkeysinspect}"
    if lnaddr.pubkey.nil?
      preimage = []
      hrp.chars.each { |c| preimage << c.ord }
      preimage += data_bs.to_bytes
      lnaddr.preimage = preimage
      lnaddr.signature = signature[0...64]
      lnaddr.recovery_flag = signature[64]
      pubkey = Bolt11::Secp256k1.recover_compact(lnaddr.preimage_hash, lnaddr.signature.pack('C*'),
                                                 lnaddr.recovery_flag, true)
      lnaddr.pubkey = pubkey.pubkey unless pubkey.nil?
    end
    lnaddr
  end

  def parse_fallback(lnaddr, fallback_data)
    return to_hex(fallback_data.to_bytes) unless %w[bc tb].include?(lnaddr.currency)

    wver = fallback_data[0...5].to_i
    lnaddr.witness_version = wver

    if wver <= 16
      return Bech32.encode(lnaddr.currency, fallback_data[0..].to_array_u5,
                           Bech32::Encoding::BECH32)
    end

    return unless [17, 18].include?(wver)

    prefix_index = wver == 17 ? 0 : 1
    prefix = BASE58_PREFIXES[lnaddr.currency.to_sym][prefix_index]

    addr_data = [prefix] + fallback_data[5..].to_bytes

    base58_encode_check(addr_data)
  end

  # decode the human readable part of the invoice
  def decode_hrp(hrp)
    m = hrp[2..].match(/[^\d]+/)
    raise ArgumentError, 'Invalid human readable part' if m.nil?

    amount_str = hrp[2 + m[0].length..]

    return [m[0], nil] if amount_str.empty?

    [m[0], unshorten_amount(amount_str)]
  end

  # Given a shortened amount, convert it into a decimal
  def unshorten_amount(amount)
    raise ArgumentError, 'Amount must be a string' unless amount.is_a? String

    # BOLT #11:
    # A reader SHOULD fail if `amount` contains a non-digit, or is followed by
    # anything except a `multiplier` in the Hash defined above.
    raise ArgumentError, 'Invalid Amount' unless amount.match?(/^\d+[pnum]?$/)

    unit = (amount[-1]).to_sym
    return BigDecimal(amount[0..-2]) / UNITS[unit] if UNITS.key? unit

    BigDecimal(amount)
  end

  def to_hex(data)
    raise ArgumentError, 'data must be an array' unless data.is_a? Array

    data.map { |v| format('%02x', v) }.join('')
  end

  def to_bin(data)
    data.chars.map { |v| v.ord }
  end

  def double_sha256(value)
    Digest::SHA256.hexdigest(Digest::SHA256.digest(to_bin(value).pack('C*')))
  end

  def base58_encode_check(value)
    value = value.pack('C*') if value.is_a? Array
    value_hex = to_hex to_bin value
    digest = double_sha256(value)
    digest_part = digest[0...8]
    Bitcoin::Base58.encode(value_hex + digest_part)
  end

  # Recover public key from compact signature.
  # @param [String] data message digest using signature.
  # @param [String] signature signature with binary format.
  # @param [Integer] rec recovery id.
  # @param [Boolean] compressed whether compressed public key or not.
  # @return [Bitcoin::Key] Recovered public key.
  def recover_compact(data, signature, rec, compressed)
    r = ECDSA::Format::IntegerOctetString.decode(signature[1...33])
    s = ECDSA::Format::IntegerOctetString.decode(signature[33..-1])
    ECDSA.recover_public_key(Bitcoin::Secp256k1::GROUP, data, ECDSA::Signature.new(r, s)).each do |p|
      return Bitcoin::Key.from_point(p, compressed:) if p.y & 1 == rec
    end
  end

  def recover_public_key(data, signature, rec)
    # signature += rec.to_s(16)
    r = ECDSA::Format::IntegerOctetString.decode(signature.htb[1...33])
    s = ECDSA::Format::IntegerOctetString.decode(signature.htb[33..-1])
    data_htb = data.htb
    signature_htb = signature.htb
    pubkey = Bolt11::Secp256k1.recover_compact(data_htb, signature_htb, rec, true)
    pubkey.pubkey unless pubkey.nil?
  end
end
