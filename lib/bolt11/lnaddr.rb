# frozen_string_literal: true

module Bolt11
  # LnAddr is a class that represents a lightning network payment invoice.
  class LnAddr
    attr_accessor :currency, :amount, :multiplier, :timestamp,
                  :pubkey, :signature, :short_description, :description,
                  :payment_hash, :description_hash, :expiry, :routing_info,
                  :fallback_addr, :unknown_tags

    def initialize
      @currency = ''
      @unknown_tags = []
      @routing_info = []
    end
  end
end
