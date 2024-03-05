require 'bitcoin'

module Bolt11
  module Secp256k1
    module_function

    extend Bitcoin::Secp256k1::Native

    # Recover public key from compact signature.
    # @param [String] data message digest using signature.
    # @param [String] signature signature with binary format.
    # @param [Integer] rec recovery id.
    # @param [Boolean] compressed whether compressed public key or not.
    # @return [Bitcoin::Key] Recovered public key.
    def recover_compact(data, signature, rec, compressed)
      raise ArgumentError, 'Invalid recovery id.' if rec < 0 || rec > 3
      raise ArgumentError, 'Invalid signature length.' if signature.bytesize != 64
      raise ArgumentError, 'Invalid data length.' if data.bytesize != 32

      with_context do |context|
        sig = FFI::MemoryPointer.new(:uchar, 64)
        input = FFI::MemoryPointer.new(:uchar, 64).put_bytes(0, signature[0..])

        result = secp256k1_ecdsa_recoverable_signature_parse_compact(context, sig, input, rec)
        raise 'secp256k1_ecdsa_recoverable_signature_parse_compact failed.' unless result == 1

        pubkey = FFI::MemoryPointer.new(:uchar, 64)
        msg = FFI::MemoryPointer.new(:uchar, data.bytesize).put_bytes(0, data)
        result = secp256k1_ecdsa_recover(context, pubkey, sig, msg)
        raise 'secp256k1_ecdsa_recover failed.' unless result == 1

        pubkey = serialize_pubkey_internal(context, pubkey.read_string(64), compressed)
        Bitcoin::Key.new(pubkey:, compressed:)
      end
    end
  end
end
