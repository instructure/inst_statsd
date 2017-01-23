require 'spec_helper'

describe CanvasStatsd::BlockStat do
  it "track exclusives correctly" do
    stat = CanvasStatsd::BlockStat.new("key")
    stat.stats['total'] = 5.0
    stat.subtract_exclusives("total" => 1.5)
    stat.subtract_exclusives("total" => 2.1)
    expect(stat.exclusive_stats).to eql("total" => 1.4)
  end
end
