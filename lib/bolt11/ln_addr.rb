# frozen_string_literal: true

module Bolt11
  # LnAddr is a class that represents a lightning network payment invoice.
  class LnAddr
    attr_accessor :currency, :amount, :multiplier, :timestamp
    # tagged fields
    attr_accessor :payment_secret, :payment_hash, :short_description, :description_hash, :expiry, :min_final_cltv_expiry_delta,
                  :pubkey, :signature, :routing_info, :unknown_tags

    # fallback
    attr_accessor :fallback_addr, :witness_version

    # signature
    attr_accessor :signature, :recovery_flag, :preimage, :preimage_hash

    def initialize
      @min_final_cltv_expiry_delta = 18
      @currency = ''
      @unknown_tags = []
      @routing_info = []
    end

    def msatoshi
      (amount * 100_000_000 * 1_000).to_i
    end

    def satoshi
      (amount * 100_000_000).to_i
    end

    def preimage_hex
      preimage.map { |v| format('%02x', v) }.join('')
    end

    def preimage_hash
      Digest::SHA256.digest(preimage.pack('C*'))
    end

    def preimage_hash_hex
      preimage_hash.unpack1('H*')
    end

    def signature_hex
      signature.map { |v| format('%02x', v) }.join('')
    end
  end
end
