require 'spec_helper'

describe InstStatsd::BlockStat do
  it "track exclusives correctly" do
    stat = InstStatsd::BlockStat.new("key")
    stat.stats['total'] = 5.0
    stat.subtract_exclusives("total" => 1.5)
    stat.subtract_exclusives("total" => 2.1)
    expect(stat.exclusive_stats).to eql("total" => 1.4)
  end
end
