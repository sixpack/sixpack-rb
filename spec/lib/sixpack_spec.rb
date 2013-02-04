require 'spec_helper'

describe Sixpack do
  it "should return an alternative for simple_participate" do
    alternative = Sixpack.simple_participate('show-bieber', ['trolled', 'not-trolled'], :client_id => "mike")
    ['trolled', 'not-trolled'].should include(alternative)
  end

  it "should return ok for simple_convert" do
    alternative = Sixpack.simple_participate('show-bieber', ['trolled', 'not-trolled'], :client_id => "mike")
    Sixpack.simple_convert("show-bieber", "mike").should == "ok"
  end

  it "should not return ok for simple_convert with new id" do
    Sixpack.simple_convert("show-bieber", "unknown_id").should == "failed"
  end

  it "should not return ok for simple_convert with new experiment" do
    alternative = Sixpack.simple_participate('show-bieber', ['trolled', 'not-trolled'], :client_id => "mike")
    Sixpack.simple_convert("show-blieber", "mike").should == "failed"
  end
end
