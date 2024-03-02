# frozen_string_literal: true

require_relative 'bolt11/version'
require_relative 'bolt11/bitstring'
require_relative 'bolt11/ln_addr'
require_relative 'bolt11/routing_info'
require 'bigdecimal'
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
    lnaddr.timestamp = data_bs.read(35).to_i
    # tagged_fields = data_part[7..data_part.length - 105] # ∵ 520 bits == 5 bits * 104
    # sigdecoded = data_part[105, data_part.length]

    while data_bs.pos < data_bs.length - 520
      tag_type = data_bs.read(5).to_i
      tag = Bech32::CHARSET[tag_type]

      data_length = data_bs.read(5).to_i * 32 + data_bs.read(5).to_i
      tag_data = data_bs.read(data_length * 5)
      case tag
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
            tag_data.read(264).to_bytes.map { |v| format('%02x', v) }.join,
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
      # when 'f'
      #   fallback = parse_fallback(tag_data, lnaddr.currency)
      #   lnaddr.fallback_addr = fallback unless fallback.nil?
      #   lnaddr.unknown_tags << [tag, tag_data] if fallback.nil?
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
        lnaddr.description_hash = tag_data.trim_to_bytes.map { |v| format('%02x', v) }.join
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
        lnaddr.payment_hash = tag_data.trim_to_bytes.map { |v| format('%02x', v) }.join
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

    # if lnaddr.pubkey.nil?
    #   # TODO: recover pubkey from signature
    # else
    #   # TODO: check signature
    # end
    lnaddr
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
end
