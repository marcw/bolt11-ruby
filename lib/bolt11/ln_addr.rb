# frozen_string_literal: true

module Bolt11
  # LnAddr is a class that represents a lightning network payment invoice.
  class LnAddr
    attr_accessor :currency, :amount, :multiplier, :timestamp
    # tagged fields
    attr_accessor :payment_hash, :short_description, :description_hash, :expiry, :min_final_cltv_expiry_delta,
                  :pubkey, :signature, :routing_info, :fallback_addr, :unknown_tags

    def initialize
      @min_final_cltv_expiry_delta = 18
      @currency = ''
      @unknown_tags = []
      @routing_info = []
    end

    def msatoshi
      (amount * 100_000_000_000_000).to_i
    end

    def satoshi
      (amount * 100_000_000_000).to_i
    end
  end
end
