# frozen_string_literal: true

RSpec.describe Bolt11 do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end

  it 'raises an error when passed an invalid invoice' do
    expect do
      described_class.decode('foobar')
    end.to raise_error(ArgumentError, 'Invalid invoice: bad bech32 checksum')
  end

  it 'raises an error when passed an invoice with an unknown prefix' do
    expect do
      described_class.decode(Bech32.encode('foo', [0, 1, 2, 3, 4, 5], Bech32::Encoding::BECH32))
    end.to raise_error(ArgumentError, 'Invalid invoice: does not start with \'ln\'')
  end

  describe '#decode_hrp' do
    it 'decodes the hrp properly' do
      currency, amount = described_class.decode_hrp('lnbc2500u')
      expect(currency).to eq 'bc'
      expect(amount).to eq BigDecimal('0.0025')
    end
  end

  describe '#unshorten_amount' do
    it 'unshortens the amount' do
      expect(described_class.unshorten_amount('10p')).to eq BigDecimal(10) / 10**12
      expect(described_class.unshorten_amount('1n')).to eq BigDecimal(1000) / 10**12
      expect(described_class.unshorten_amount('1200p')).to eq BigDecimal(1200) / 10**12
      expect(described_class.unshorten_amount('123u')).to eq BigDecimal(123) / 10**6
      expect(described_class.unshorten_amount('123m')).to eq BigDecimal(123) / 1000
      expect(described_class.unshorten_amount('3')).to eq BigDecimal(3)
    end

    it 'raises an error when passed an invalid multiplier' do
      expect { described_class.unshorten_amount('10x') }.to raise_error ArgumentError
      expect { described_class.unshorten_amount('1.0u') }.to raise_error ArgumentError
    end
  end

  describe '#decode bolt11 examples' do
    examples = [
      {
        bolt11: 'lnbc1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpl2pkx2ctnv5sxxmmwwd5kgetjypeh2ursdae8g6twvus8g6rfwvs8qun0dfjkxaq9qrsgq357wnc5r2ueh7ck6q93dj32dlqnls087fxdwk8qakdyafkq3yap9us6v52vjjsrvywa6rt52cm9r9zqt8r2t7mlcwspyetp5h2tztugp9lfyql',
        currency: 'bc',
        timestamp: 1_496_314_658,
        amount: nil,
        payment_secret: '1111111111111111111111111111111111111111111111111111111111111111',
        payment_hash: '0001020304050607080900010203040506070809000102030405060708090102',
        short_description: 'Please consider supporting this project',
        signature_hex: '8d3ce9e28357337f62da0162d9454df827f83cfe499aeb1c1db349d4d81127425e434ca29929406c23bba1ae8ac6ca32880b38d4bf6ff874024cac34ba9625f1',
        preimage_hex: '6c6e62630b25fe64500d04444444444444444444444444444444444444444444444444444444444444444021a00008101820283038404800081018202830384048000810182028303840480810343f506c6561736520636f6e736964657220737570706f7274696e6720746869732070726f6a6563740500e08000',
        preimage_hash_hex: '6daf4d488be41ce7cbb487cab1ef2975e5efcea879b20d421f0ef86b07cbb987',
        recovery_flag: 1,
        pubkey: '03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad'
      },
      {
        bolt11: 'lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpu9qrsgquk0rl77nj30yxdy8j9vdx85fkpmdla2087ne0xh8nhedh8w27kyke0lp53ut353s06fv3qfegext0eh0ymjpf39tuven09sam30g4vgpfna3rh',
        currency: 'bc',
        timestamp: 1_496_314_658,
        pubkey: '03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad',
        amount: BigDecimal('0.0025'),
        payment_secret: '1111111111111111111111111111111111111111111111111111111111111111',
        payment_hash: '0001020304050607080900010203040506070809000102030405060708090102',
        short_description: '1 cup coffee',
        expiry: 60,
        signature_hex: 'e59e3ffbd3945e4334879158d31e89b076dff54f3fa7979ae79df2db9dcaf5896cbfe1a478b8d2307e92c88139464cb7e6ef26e414c4abe33337961ddc5e8ab1',
        recovery_flag: 1,
        preimage_hex: '6c6e626332353030750b25fe64500d04444444444444444444444444444444444444444444444444444444444444444021a000081018202830384048000810182028303840480008101820283038404808103414312063757020636f66666565030041e140382000',
        preimage_hash_hex: '047e24bf270b25d42a56d57b2578faa3a10684641bab817c2851a871cb41dbc0'
      },
      {
        bolt11: 'lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpquwpc4curk03c9wlrswe78q4eyqc7d8d0xqzpu9qrsgqhtjpauu9ur7fw2thcl4y9vfvh4m9wlfyz2gem29g5ghe2aak2pm3ps8fdhtceqsaagty2vph7utlgj48u0ged6a337aewvraedendscp573dxr',
        currency: 'bc',
        timestamp: 1_496_314_658,
        pubkey: '03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad',
        amount: BigDecimal('0.0025'),
        payment_secret: '1111111111111111111111111111111111111111111111111111111111111111',
        payment_hash: '0001020304050607080900010203040506070809000102030405060708090102',
        short_description: 'ナンセンス 1杯',
        expiry: 60,
        signature_hex: 'bae41ef385e0fc972977c7ea42b12cbd76577d2412919da8a8a22f9577b6507710c0e96dd78c821dea16453037f717f44aa7e3d196ebb18fbb97307dcb7336c3',
        recovery_flag: 1,
        preimage_hex: '6c6e626332353030750b25fe64500d04444444444444444444444444444444444444444444444444444444444444444021a000081018202830384048000810182028303840480008101820283038404808103420e3838ae383b3e382bbe383b3e382b92031e69daf30041e14038200',
        preimage_hash_hex: 'f140d992ba419578ba9cfe1af85f92df90a76f442fb5e6e09b1f0582534ba87d'
      },
      {
        bolt11: 'lnbc20m1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqs9qrsgq7ea976txfraylvgzuxs8kgcw23ezlrszfnh8r6qtfpr6cxga50aj6txm9rxrydzd06dfeawfk6swupvz4erwnyutnjq7x39ymw6j38gp7ynn44',
        currency: 'bc',
        timestamp: 1_496_314_658,
        amount: BigDecimal('0.02'),
        pubkey: '03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad',
        payment_secret: '1111111111111111111111111111111111111111111111111111111111111111',
        payment_hash: '0001020304050607080900010203040506070809000102030405060708090102',
        description_hash: '8yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqs',
        signature_hex: 'f67a5f696648fa4fb102e1a07b230e54722f8e024cee71e80b4847ac191da3fb2d2cdb28cc32344d7e9a9cf5c9b6a0ee0582ae46e9938b9c81e344a4dbb5289d',
        recovery_flag: 1,
        preimage_hex: '6c6e626332306d0b25fe64500d04444444444444444444444444444444444444444444444444444444444444444021a000081018202830384048000810182028303840480008101820283038404808105c343925b6f67e2c340036ed12093dd44e0368df1b6ea26c53dbe4811f58fd5db8c10280704000',
        preimage_hash_hex: 'e2ffa444e2979edb639fbdaa384638683ba1a5240b14dd7a150e45a04eea261d'
      },
      {
        bolt11: 'lntb20m1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygshp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqfpp3x9et2e20v6pu37c5d9vax37wxq72un989qrsgqdj545axuxtnfemtpwkc45hx9d2ft7x04mt8q7y6t0k2dge9e7h8kpy9p34ytyslj3yu569aalz2xdk8xkd7ltxqld94u8h2esmsmacgpghe9k8',
        currency: 'tb',
        timestamp: 1_496_314_658,
        amount: BigDecimal('0.02'),
        description_hash: '8yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqs',
        payment_secret: '1111111111111111111111111111111111111111111111111111111111111111',
        payment_hash: '0001020304050607080900010203040506070809000102030405060708090102',
        pubkey: '03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad',
        fallback_addr: 'mk2QpYatsKicvFVuTAQLBryyccRXMUaGHP',
        signature_hex: '6ca95a74dc32e69ced6175b15a5cc56a92bf19f5dace0f134b7d94d464b9f5cf6090a18d48b243f289394d17bdf89466d8e6b37df5981f696bc3dd5986e1bee1',
        recovery_flag: 1,
        preimage_hex: '6c6e746232306d0b25fe64500d044444444444444444444444444444444444444444444444444444444444444442e1a1c92db7b3f161a001b7689049eea2701b46f8db7513629edf2408fac7eaedc608043400010203040506070809000102030405060708090001020304050607080901020484313172b5654f6683c8fb146959d347ce303cae4ca728070400',
        preimage_hash_hex: '33bc6642a336097c74299cadfdfdd2e4884a555cf1b4fda72b095382d473d795'
      },
      {
        bolt11: 'lnbc20m1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqsfpp3qjmp7lwpagxun9pygexvgpjdc4jdj85fr9yq20q82gphp2nflc7jtzrcazrra7wwgzxqc8u7754cdlpfrmccae92qgzqvzq2ps8pqqqqqqpqqqqq9qqqvpeuqafqxu92d8lr6fvg0r5gv0heeeqgcrqlnm6jhphu9y00rrhy4grqszsvpcgpy9qqqqqqgqqqqq7qqzq9qrsgqdfjcdk6w3ak5pca9hwfwfh63zrrz06wwfya0ydlzpgzxkn5xagsqz7x9j4jwe7yj7vaf2k9lqsdk45kts2fd0fkr28am0u4w95tt2nsq76cqw0',
        currency: 'bc',
        timestamp: 1_496_314_658,
        amount: BigDecimal('0.02'),
        payment_secret: '1111111111111111111111111111111111111111111111111111111111111111',
        payment_hash: '0001020304050607080900010203040506070809000102030405060708090102',
        description_hash: '8yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqs',
        pubkey: '03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad',
        witness_version: 17,
        fallback_addr: '1RustyRX2oai4EYYDpQGWvEL62BBGqN9T',
        signature_hex: '6a6586db4e8f6d40e3a5bb92e4df5110c627e9ce493af237e20a046b4e86ea200178c59564ecf892f33a9558bf041b6ad2cb8292d7a6c351fbb7f2ae2d16b54e',
        recovery_flag: 0,
        preimage_hex: '6c6e626332306d0b25fe64500d04444444444444444444444444444444444444444444444444444444444444444021a000081018202830384048000810182028303840480008101820283038404808105c343925b6f67e2c340036ed12093dd44e0368df1b6ea26c53dbe4811f58fd5db8c104843104b61f7dc1ea0dc99424464cc4064dc564d91e891948053c07520370aa69fe3d258878e8863ef9ce408c0c1f9ef52b86fc291ef18ee4aa020406080a0c0e1000000002000000280006073c07520370aa69fe3d258878e8863ef9ce408c0c1f9ef52b86fc291ef18ee4aa06080a0c0e101214000000040000003c00080500e08000',
        preimage_hash_hex: 'b342d4655b984e53f405fe4d872fb9b7cf54ba538fcd170ed4a5906a9f535064',
        routing_info: [
          {
            pubkey: '029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255',
            short_channel_id: '66051x263430x1800',
            fee_base_msat: 1,
            fee_proportional_millionths: 20,
            cltv_expiry_delta: 3
          },
          {
            pubkey: '039e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255',
            short_channel_id: '197637x395016x2314',
            fee_base_msat: 2,
            fee_proportional_millionths: 30,
            cltv_expiry_delta: 4
          }
        ]
      },
      {
        bolt11: 'lnbc20m1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygshp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqfppj3a24vwu6r8ejrss3axul8rxldph2q7z99qrsgqz6qsgww34xlatfj6e3sngrwfy3ytkt29d2qttr8qz2mnedfqysuqypgqex4haa2h8fx3wnypranf3pdwyluftwe680jjcfp438u82xqphf75ym',
        currency: 'bc',
        timestamp: 1_496_314_658,
        amount: BigDecimal('0.02'),
        payment_secret: '1111111111111111111111111111111111111111111111111111111111111111',
        payment_hash: '0001020304050607080900010203040506070809000102030405060708090102',
        pubkey: '03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad',
        description_hash: '8yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqs',
        witness_version: 18,
        fallback_addr: '3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX',
        signature_hex: '16810439d1a9bfd5a65acc61340dc92448bb2d456a80b58ce012b73cb5202438020500c9ab7ef5573a4d174c811f669885ae27f895bb3a3be52c243589f87518',
        recovery_flag: 1,
        preimage_hex: '6c6e626332306d0b25fe64500d044444444444444444444444444444444444444444444444444444444444444442e1a1c92db7b3f161a001b7689049eea2701b46f8db7513629edf2408fac7eaedc608043400010203040506070809000102030405060708090001020304050607080901020484328f55563b9a19f321c211e9b9f38cdf686ea0784528070400',
        preimage_hash_hex: '9e93321a775f7dffdca03e61d1ac6e0e356cc63cecd3835271200c1e5b499d29'
      },
      {
        bolt11: 'lnbc20m1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygshp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqfppqw508d6qejxtdg4y5r3zarvary0c5xw7k9qrsgqt29a0wturnys2hhxpner2e3plp6jyj8qx7548zr2z7ptgjjc7hljm98xhjym0dg52sdrvqamxdezkmqg4gdrvwwnf0kv2jdfnl4xatsqmrnsse',
        currency: 'bc',
        timestamp: 1_496_314_658,
        amount: BigDecimal('0.02'),
        payment_secret: '1111111111111111111111111111111111111111111111111111111111111111',
        payment_hash: '0001020304050607080900010203040506070809000102030405060708090102',
        description_hash: '8yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqs',
        pubkey: '03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad',
        witness_version: 0,
        fallback_addr: 'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4',
        signature_hex: '5a8bd7b97c1cc9055ee60cf2356621f8752248e037a953886a1782b44a58f5ff2d94e6bc89b7b514541a3603bb33722b6c08aa1a3639d34becc549a99fea6eae',
        recovery_flag: 0,
        preimage_hex: '6c6e626332306d0b25fe64500d044444444444444444444444444444444444444444444444444444444444444442e1a1c92db7b3f161a001b7689049eea2701b46f8db7513629edf2408fac7eaedc60804340001020304050607080900010203040506070809000102030405060708090102048420751e76e8199196d454941c45d1b3a323f1433bd628070400',
        preimage_hash_hex: '44fbec32cdac99a1a3cd638ec507dad633a1e5bba514832fd3471e663a157f7b'
      },
      {
        bolt11: 'lnbc20m1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygshp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqfp4qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q9qrsgq9vlvyj8cqvq6ggvpwd53jncp9nwc47xlrsnenq2zp70fq83qlgesn4u3uyf4tesfkkwwfg3qs54qe426hp3tz7z6sweqdjg05axsrjqp9yrrwc',
        currency: 'bc',
        timestamp: 1_496_314_658,
        amount: BigDecimal('0.02'),
        payment_secret: '1111111111111111111111111111111111111111111111111111111111111111',
        payment_hash: '0001020304050607080900010203040506070809000102030405060708090102',
        pubkey: '03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad',
        description_hash: '8yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqs',
        witness_version: 0,
        fallback_addr: 'bc1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qccfmv3',
        signature_hex: '2b3ec248f80301a421817369194f012cdd8af8df1c279981420f9e901e20fa3309d791e11355e609b59ce4a220852a0cd55ab862b1785a83b206c90fa74d01c8',
        recovery_flag: 1,
        preimage_hex: '6c6e626332306d0b25fe64500d044444444444444444444444444444444444444444444444444444444444444442e1a1c92db7b3f161a001b7689049eea2701b46f8db7513629edf2408fac7eaedc608043400010203040506070809000102030405060708090001020304050607080901020486a01863143c14c5166804bd19203356da136c985678cd4d27a1b8c63296049032620280704000',
        preimage_hash_hex: '865a2cc6730e1eeeacd30e6da8e9ab0e9115828d27953ec0c0f985db05da5027'
      },
      {
        bolt11: 'lnbc9678785340p1pwmna7lpp5gc3xfm08u9qy06djf8dfflhugl6p7lgza6dsjxq454gxhj9t7a0sd8dgfkx7cmtwd68yetpd5s9xar0wfjn5gpc8qhrsdfq24f5ggrxdaezqsnvda3kkum5wfjkzmfqf3jkgem9wgsyuctwdus9xgrcyqcjcgpzgfskx6eqf9hzqnteypzxz7fzypfhg6trddjhygrcyqezcgpzfysywmm5ypxxjemgw3hxjmn8yptk7untd9hxwg3q2d6xjcmtv4ezq7pqxgsxzmnyyqcjqmt0wfjjq6t5v4khxsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygsxqyjw5qcqp2rzjq0gxwkzc8w6323m55m4jyxcjwmy7stt9hwkwe2qxmy8zpsgg7jcuwz87fcqqeuqqqyqqqqlgqqqqn3qq9q9qrsgqrvgkpnmps664wgkp43l22qsgdw4ve24aca4nymnxddlnp8vh9v2sdxlu5ywdxefsfvm0fq3sesf08uf6q9a2ke0hc9j6z6wlxg5z5kqpu2v9wz',
        currency: 'bc',
        timestamp: 1_572_468_703,
        amount: BigDecimal('0.00967878534'),
        payment_secret: '1111111111111111111111111111111111111111111111111111111111111111',
        pubkey: '03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad',
        # payment_hash: 'gc3xfm08u9qy06djf8dfflhugl6p7lgza6dsjxq454gxhj9t7a0s'
        payment_hash: '462264ede7e14047e9b249da94fefc47f41f7d02ee9b091815a5506bc8abf75f',
        description_hash: '8yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqs',
        short_description: 'Blockstream Store: 88.85 USD for Blockstream Ledger Nano S x 1, "Back In My Day" Sticker x 2, "I Got Lightning Working" Sticker x 2 and 1 more items',
        expiry: 604_800,
        min_final_cltv_expiry_delta: 10,
        routing_info: [
          {
            pubkey: '03d06758583bb5154774a6eb221b1276c9e82d65bbaceca806d90e20c108f4b1c7',
            short_channel_id: '589390x3312x1',
            fee_base_msat: 1000,
            fee_proportional_millionths: 2500,
            cltv_expiry_delta: 40
          }
        ]
      }
    ]

    examples.each do |example|
      describe "example: #{example[:bolt11]}" do
        let(:lnaddr) do
          described_class.decode(example[:bolt11])
        end

        example.each_pair do |key, value|
          next if key == :bolt11

          if key == :routing_info
            value.each_with_index do |routing_info, index|
              routing_info.each_pair do |routing_info_key, routing_info_value|
                it "decoded the routing_info[#{index}].#{routing_info_key} to '#{routing_info_value.inspect}'" do
                  skip 'short_channel_id is not implemented yet' if routing_info_key == :short_channel_id
                  expect(lnaddr.routing_info[index].send(routing_info_key)).to eq routing_info_value
                end
              end
            end
            next
          end

          it "decoded the #{key} to '#{value.inspect}'" do
            skip 'testing min_final_cltv_expiry_delta is not implemented yet' if key == :min_final_cltv_expiry_delta
            skip 'description_hash is not implemented yet' if key == :description_hash
            # skip 'fallback address is not implemented yet' if key == :fallback_addr
            expect(lnaddr.send(key)).to eq value
          end
        end
      end
    end
  end

  describe 'real-life bolt11' do
    let(:lnaddr) do
      described_class.decode('lnbc210n1pju4tuvpp5v2648e92tytdekcxjy4d8r5902tdw6qn9h87zu3mtsvjyfq0su3qhp5c0867py9e7pjf6mn7g29yk5gczzdjwkzz8hejy2wslygfgslsf3qcqzzsxqyz5vqsp5pxx2qq995vffk9gk2juthe0k2sf0uue9g0nj457aafcheduzwyls9qyyssqgxep9l4xa7lcxgednprfdjx4ja0gcvzl23ycr36hp25crtw6z34kv04nhprar72drwmkrsg7rm0z3c3q8zn2wcaeqh3nvpag6n09waspn7lmkg')
    end

    it 'decoded the pubkey' do
      expect(lnaddr.pubkey).to eq '035e4ff418fc8b5554c5d9eea66396c227bd429a3251c8cbc711002ba215bfc226'
    end

    it 'decoded the amount' do
      expect(lnaddr.msatoshi).to eq 21_000
      expect(lnaddr.satoshi).to eq 21
    end
  end

  describe '#double_sha256' do
    it 'digest two times' do
      expect(described_class.double_sha256('foobar')).to eq '3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda1'
    end
  end

  describe '#base58_encode_check' do
    parameters = [
      [[12, 24], '72LE2XTz'],
      ['foobar', '6knpiKjKZoKt7K'],
      ['hello world', '3vQB7B6MrGQZaxCuFg4oh']
    ]
    parameters.each do |params|
      it "encodes #{params[0].inspect} to '#{params[1].inspect}" do
        expect(described_class.base58_encode_check(params[0])).to eq params[1]
      end
    end
  end
end
