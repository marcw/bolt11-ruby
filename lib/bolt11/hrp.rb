# frozen_string_literal: true

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
