# frozen_string_literal: true

RSpec.describe Bolt11::Bitstring do
  describe '#initialize' do
    it 'initializes with 5-bits encoded arrays' do
      invoice = 'lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzq' \
                'fqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpu9qrsgquk0rl77nj30yxdy8j9v' \
                'dx85fkpmdla2087ne0xh8nhedh8w27kyke0lp53ut353s06fv3qfegext0eh0ymjpf39tuven09sam30g4vgpfna3rh'
      _hrp, data_part = Bech32.decode(invoice, 1024)
      expect(described_class.new(data_part).length).to eq data_part.length * 5
    end

    it 'initializes with a string' do
      expect(described_class.new('00001').length).to eq 5
    end
  end

  describe '#length' do
    params = [
      ['00001011001001011111111001100100010', 35],
      ['000001', 6],
      ['00001', 5],
      ['1', 1]
    ]
    params.each do |parameter|
      it "returns the length of the '#{parameter[0]}' binary string" do
        expect(described_class.new(parameter[0]).length).to eq parameter[1]
      end
    end
  end

  describe '#to_bytes' do
    params = [
      ['00001', [8]],
      ['00001001', [9]],
      ['0000100001', [8, 64]],
      ['0000100100001001', [9, 9]]
    ]
    params.each do |parameter|
      it "converts '#{parameter[0]}' binary string to '#{parameter[1]}'" do
        expect(described_class.new(parameter[0]).to_bytes).to eq parameter[1]
      end
    end
  end

  describe '#int' do
    params = [
      ['0000000000000001', 1],
      ['00000000000000000000000000000001', 1]
    ]

    params.each do |parameter|
      it "converts '#{parameter[0]}' binary string to '#{parameter[1]}'" do
        expect(described_class.new(parameter[0]).int).to eq parameter[1]
      end
    end
  end

  describe '#to_i' do
    params =
      [
        ['00001', 1],
        ['11111', 31],
        ['0000100000', 32],
        ['0000100001', 33],
        ['00001011001001011111111001100100010', 1_496_314_658]
      ]

    params.each do |parameter|
      it "converts '#{parameter[0]}' binary string to '#{parameter[1]}'" do
        expect(described_class.new(parameter[0]).to_i).to eq parameter[1]
      end
    end
  end

  describe '#trim_to_bytes' do
    it 'trims a 35-bits binary string to 4 bytes' do
      bs = described_class.new('00001011001001011111111001100100010')
      expect(bs.trim_to_bytes).to eq [11, 37, 254, 100]
    end
  end
end
