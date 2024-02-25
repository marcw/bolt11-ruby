RSpec.describe Bolt11 do
  describe 'BitString' do
    invoice = 'lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpu9qrsgquk0rl77nj30yxdy8j9vdx85fkpmdla2087ne0xh8nhedh8w27kyke0lp53ut353s06fv3qfegext0eh0ymjpf39tuven09sam30g4vgpfna3rh'
    describe '#initialize' do
      it 'with 5-bits encoded arrays' do
        _hrp, data_part = Bech32.decode(invoice, 1024)
        bs = Bolt11::BitString.new(data_part)
        expect(bs.length).to eq data_part.length * 5
      end

      it 'initializes with a string' do
        bs = Bolt11::BitString.new('00001')
        expect(bs.length).to eq 5
        expect(bs.to_i).to eq 1
      end
    end

    describe '#length' do
      it 'returns the length of the 35 bits-binary string' do
        bs = Bolt11::BitString.new('00001011001001011111111001100100010')
        expect(bs.length).to eq 35
      end

      it 'returns the length of the 6 bits-binary string' do
        bs = Bolt11::BitString.new('000001')
        expect(bs.length).to eq 6
      end

      it 'returns the length of the 5 bits-binary string' do
        bs = Bolt11::BitString.new('00001')
        expect(bs.length).to eq 5
      end

      it 'returns the length of the 1 bits-binary string' do
        bs = Bolt11::BitString.new('1')
        expect(bs.length).to eq 1
      end
    end

    describe '#to_bytes' do
      it 'converts a 5-bits binary string' do
        bs = Bolt11::BitString.new('00001')
        expect(bs.to_bytes).to eq [8]
      end

      it 'converts a 8-bits binary string' do
        bs = Bolt11::BitString.new('00001001')
        expect(bs.to_bytes).to eq [9]
      end

      it 'converts a 10-bits binary string' do
        bs = Bolt11::BitString.new('0000100001')
        expect(bs.to_bytes).to eq [8, 64]
      end

      it 'converts a 16-bits binary string' do
        bs = Bolt11::BitString.new('0000100100001001')
        expect(bs.to_bytes).to eq [9, 9]
      end

      it 'converts a 10-bits binary string' do
        bs = Bolt11::BitString.new('0000100001')
        expect(bs.to_bytes).to eq [8, 64]
      end
    end

    describe '#intbe' do
      it 'converts a 16-bits binary string to an integer' do
        bs = Bolt11::BitString.new('0000000000000001')
        expect(bs.int).to eq 1
      end

      it 'converts a 32-bits binary string to an integer' do
        bs = Bolt11::BitString.new('0000000000000000000000000000001')
        expect(bs.int).to eq 1
      end
    end

    describe '#to_i' do
      it 'converts a 5-bits binary string' do
        bs = Bolt11::BitString.new('00001')
        expect(bs.to_i).to eq 1
        bs = Bolt11::BitString.new('11111')
        expect(bs.to_i).to eq 31
      end

      it 'converts a 10-bits binary string to an integer' do
        bs = Bolt11::BitString.new('0000100000')
        expect(bs.to_i).to eq 32

        bs = Bolt11::BitString.new('0000100001')
        expect(bs.to_i).to eq 33
      end

      it 'converts a 35-bits binary string to an integer' do
        bs = Bolt11::BitString.new('00001011001001011111111001100100010')
        expect(bs.to_i).to eq 1_496_314_658
      end
    end

    describe '#trim_to_bytes' do
    end

    # it 'handles' do
    # expect(bs.read(35).to_i).to eq 1_496_314_658

    # expect(lnaddr.currency).to eq 'bc'
    # expect(lnaddr.amount).to eq BigDecimal('0.0025')
    # expect(lnaddr.timestamp).to eq 1_496_314_658
    # expect(lnaddr.short_description).to eq "1 cup coffee\u0003"
    # expect(lnaddr.expiry).to eq 60
    # end
  end
end
