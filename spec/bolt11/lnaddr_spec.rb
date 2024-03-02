RSpec.describe Bolt11::LnAddr do
  describe '#satoshi' do
    it 'returns the amount in satoshi' do
      lnaddr = described_class.new
      lnaddr.amount = BigDecimal('0.0025')
      expect(lnaddr.satoshi).to eq 250_000
    end
  end

  describe '#msatoshi' do
    it 'returns the amount in msatoshi' do
      lnaddr = described_class.new
      lnaddr.amount = BigDecimal('0.0025')
      expect(lnaddr.msatoshi).to eq 250_000_000
    end
  end
end
