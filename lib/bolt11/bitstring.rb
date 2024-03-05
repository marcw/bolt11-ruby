# frozen_string_literal: true

module Bolt11
  # Bitstring is a class that represents a binary string of 5bits integers.
  class Bitstring
    attr_reader :binary
    attr_accessor :pos

    def initialize(data)
      @pos = 0
      if data.is_a? String
        @binary = data
      elsif data.is_a? Array
        @binary = pack_uint5(data)
      end
    end

    def read(bits)
      raise "index out of range pos=#{pos}, bits=#{bits}, length=#{length}" if pos + bits > length

      x = @binary[pos...pos + bits]
      @pos += bits
      Bitstring.new(x)
    end

    def length
      @binary.length
    end

    def [](index)
      Bitstring.new(@binary[index])
    end

    def to_array_u5
      @binary.chars.each_slice(5).map(&:join).map do |val|
        val.to_i(2)
      end
    end

    # Splits the binary string to an array of 5-bits binary strings
    def to_a
      return [Bitstring.new(@binary)] if @binary.length <= 5

      @binary.chars.each_slice(5).map(&:join).map do |val|
        Bitstring.new(val)
      end
    end

    # Converts the binary string to an array of 8-bit integers
    def to_bytes
      padding = ''
      padding = '0' * (8 - @binary.length % 8) if @binary.length % 8 != 0
      binary = "#{@binary}#{padding}"
      binary.chars.each_slice(8).map(&:join).map { |val| val.to_i(2) }
    end

    # Converts the binary string to an array of 8-bit integers and trims the
    # last byte if the binary string wasn't a multiple of 8
    def trim_to_bytes
      bytes = to_bytes
      return bytes[0...-1] if length % 8 != 0

      bytes
    end

    # to_i converts the 5-bits based binary string to an integer.
    # if the lengthof the binary string is 5, it returns the integer value of the binary
    # string (padded with 0s to the left).
    # if the length of the binary string is not 5, it returns the integer value
    # of the binary string.
    def to_i
      return @binary.to_i(2) if length <= 5

      base10 = 0
      arr = to_a
      len = arr.length
      arr.each_with_index do |val, i|
        i = len - 1 - i
        base10 |= val.to_i << (5 * i)
      end
      base10
    end

    # converts the 8-bit based binary string to an integer
    def int
      @binary.to_i(2)
    end

    def to_s
      @binary
    end

    def inspect
      return "Bitstring: #{@binary}" if @binary.length <= 5

      "Bitstring: #{@binary.chars.each_slice(5).map(&:join).join('_')}"
    end

    private

    # Packs the content of bech32_arr into a binary string.
    # bech32_arr is an array of 5-bit integers, typically obtained by decoding a
    # bech32-encoded string.
    #
    # @param [Array<Integer>] bech32_arr
    # @return [String]
    def pack_uint5(bech32_arr)
      binary = String.new
      bech32_arr.each { |a| binary += format('%05d', a.to_s(2)) }
      binary
    end
  end
end
