RSpec.describe Bolt11 do
  it 'has a version number' do
    expect(Bolt11::VERSION).not_to be nil
  end

  it 'raises an error when passed an invalid invoice' do
    expect do
      Bolt11.decode('foobar')
    end.to raise_error(ArgumentError, 'Invalid invoice: bad bech32 checksum')
  end

  it 'raises an error when passed an invoice with an unknown prefix' do
    expect do
      Bolt11.decode(Bech32.encode('foo', [0, 1, 2, 3, 4, 5], Bech32::Encoding::BECH32))
    end.to raise_error(ArgumentError, 'Invalid invoice: does not start with \'ln\'')
  end

  describe '#decode_hrp' do
    it 'decodes the hrp properly' do
      currency, amount = Bolt11.decode_hrp('lnbc2500u')
      expect(currency).to eq 'bc'
      expect(amount).to eq BigDecimal('0.0025')
    end
  end

  describe '#unshorten_amount' do
    it 'unshortens the amount' do
      expect(Bolt11.unshorten_amount('10p')).to eq BigDecimal(10) / 10**12
      expect(Bolt11.unshorten_amount('1n')).to eq BigDecimal(1000) / 10**12
      expect(Bolt11.unshorten_amount('1200p')).to eq BigDecimal(1200) / 10**12
      expect(Bolt11.unshorten_amount('123u')).to eq BigDecimal(123) / 10**6
      expect(Bolt11.unshorten_amount('123m')).to eq BigDecimal(123) / 1000
      expect(Bolt11.unshorten_amount('3')).to eq BigDecimal(3)
    end

    it 'raises an error when passed an invalid multiplier' do
      expect { Bolt11.unshorten_amount('10x') }.to raise_error ArgumentError
      expect { Bolt11.unshorten_amount('1.0u') }.to raise_error ArgumentError
    end
  end

  describe '#decode (example 1)' do
    lnaddr = Bolt11.decode('lnbc1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpl2pkx2ctnv5sxxmmwwd5kgetjypeh2ursdae8g6twvus8g6rfwvs8qun0dfjkxaq9qrsgq357wnc5r2ueh7ck6q93dj32dlqnls087fxdwk8qakdyafkq3yap9us6v52vjjsrvywa6rt52cm9r9zqt8r2t7mlcwspyetp5h2tztugp9lfyql')
    it 'decoded the invoice properly' do
      expect(lnaddr.payment_hash).to eq '0001020304050607080900010203040506070809000102030405060708090102'
    end
  end

  # Example 1:
  # Please make a donation of any amount using payment_hash 0001020304050607080900010203040506070809000102030405060708090102 to me @03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad
  # decode 'bolt11 example 1' do
  # end

  # Example 2:
  # Please send $3 for a cup of coffee to the same peer, within one minute
  describe '#decode (example 2)' do
    lnaddr = Bolt11.decode('lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpu9qrsgquk0rl77nj30yxdy8j9vdx85fkpmdla2087ne0xh8nhedh8w27kyke0lp53ut353s06fv3qfegext0eh0ymjpf39tuven09sam30g4vgpfna3rh')

    it 'decoded the currency' do
      expect(lnaddr.currency).to eq 'bc'
    end

    it 'decoded the amount' do
      expect(lnaddr.amount).to eq BigDecimal('0.0025')
    end

    it 'decoded the timestamp' do
      expect(lnaddr.timestamp).to eq 1_496_314_658
    end

    describe 'tagged fields:' do
      it 'decoded the short description' do
        expect(lnaddr.short_description).to eq '1 cup coffee'
      end

      it 'decoded expiry' do
        expect(lnaddr.expiry).to eq 60
      end
    end
  end

  # Example 3
  # Please send 0.0025 BTC for a cup of nonsense (ナンセンス 1杯) to the same peer, within one minute
  describe '#decode (example 3)' do
    lnaddr = Bolt11.decode('lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpquwpc4curk03c9wlrswe78q4eyqc7d8d0xqzpu9qrsgqhtjpauu9ur7fw2thcl4y9vfvh4m9wlfyz2gem29g5ghe2aak2pm3ps8fdhtceqsaagty2vph7utlgj48u0ged6a337aewvraedendscp573dxr')
    it 'decoded the currency' do
      expect(lnaddr.currency).to eq 'bc'
    end

    it 'decoded the amount' do
      expect(lnaddr.amount).to eq BigDecimal('0.0025')
    end

    it 'decoded the timestamp' do
      expect(lnaddr.timestamp).to eq 1_496_314_658
    end

    describe 'tagged fields:' do
      it 'decoded the short description' do
        expect(lnaddr.short_description).to eq 'ナンセンス 1杯'
      end

      it 'decoded expiry' do
        expect(lnaddr.expiry).to eq 60
      end
    end
  end

  describe 'bolt11 with routing info' do
    lnaddr = Bolt11.decode('lnbc20m1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqsfpp3qjmp7lwpagxun9pygexvgpjdc4jdj85fr9yq20q82gphp2nflc7jtzrcazrra7wwgzxqc8u7754cdlpfrmccae92qgzqvzq2ps8pqqqqqqpqqqqq9qqqvpeuqafqxu92d8lr6fvg0r5gv0heeeqgcrqlnm6jhphu9y00rrhy4grqszsvpcgpy9qqqqqqgqqqqq7qqzq9qrsgqdfjcdk6w3ak5pca9hwfwfh63zrrz06wwfya0ydlzpgzxkn5xagsqz7x9j4jwe7yj7vaf2k9lqsdk45kts2fd0fkr28am0u4w95tt2nsq76cqw0')
    it 'decoded the base info' do
      expect(lnaddr.currency).to eq 'bc'
      expect(lnaddr.amount).to eq BigDecimal('0.02')
      expect(lnaddr.timestamp).to eq 1_496_314_658
    end

    it 'decoded two routing informations' do
      expect(lnaddr.routing_info.length).to eq 2
    end

    describe 'first routing info' do
      route = lnaddr.routing_info[0]

      it 'decoded fee_base_msat' do
        expect(route.fee_base_msat).to eq 1
      end

      it 'decoded fee_proportional_millionths' do
        expect(route.fee_proportional_millionths).to eq 20
      end

      it 'decoded cltv_expiry_delta' do
        expect(route.cltv_expiry_delta).to eq 3
      end

      it 'decoded short_channel_id' do
        skip 'string conversion not implemented yet'
        # expect(route.short_channel_id).to eq '66051x263430x1800'
      end

      it 'decoded pubkey' do
        expect(route.pubkey).to eq '029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255'
      end
    end

    describe 'second routing info' do
      route = lnaddr.routing_info[1]
      it 'decoded fee_base_msat' do
        expect(route.fee_base_msat).to eq 2
      end

      it 'decoded fee_proportional_millionths' do
        expect(route.fee_proportional_millionths).to eq 30
      end

      it 'decoded cltv_expiry_delta' do
        expect(route.cltv_expiry_delta).to eq 4
      end

      it 'decoded short_channel_id' do
        skip 'string conversion not implemented yet'
        # expect(route.short_channel_id).to eq '197637x395016x2314'
      end

      it 'decoded pubkey' do
        expect(route.pubkey).to eq '039e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255'
      end
    end
  end
end
