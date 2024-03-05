RSpec.describe Bolt11 do
  describe '#recover_public_key' do
    it 'recovers the public key from the signature' do
      recovery_flag = 1
      signature_hex = 'e59e3ffbd3945e4334879158d31e89b076dff54f3fa7979ae79df2db9dcaf5896cbfe1a478b8d2307e92c88139464cb7e6ef26e414c4abe33337961ddc5e8ab1'
      signed_data_hex = '6c6e626332353030750b25fe64500d04444444444444444444444444444444444444444444444444444444444444444021a000081018202830384048000810182028303840480008101820283038404808103414312063757020636f66666565030041e140382000'
      signed_hashed_hex = '047e24bf270b25d42a56d57b2578faa3a10684641bab817c2851a871cb41dbc0'

      expected_pubkey = '03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad'

      expect(described_class.recover_public_key(signed_hashed_hex, signature_hex,
                                                recovery_flag)).to eq '03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad'
    end
  end
end
