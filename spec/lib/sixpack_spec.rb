require 'redis'

require 'spec_helper'

describe Sixpack do
  before(:each) do
    redis = Redis.new
    redis.keys("*").each do |k|
      redis.del(k)
    end
  end

  it "should return an alternative for simple_participate" do
    alternative = Sixpack.simple_participate('show-bieber', ['trolled', 'not-trolled'], "mike")
    ['trolled', 'not-trolled'].should include(alternative)
  end

  it "should auto generate a client_id" do
    alternative = Sixpack.simple_participate('show-bieber', ['trolled', 'not-trolled'], nil)
    ['trolled', 'not-trolled'].should include(alternative)
  end

  it "should return ok for simple_convert" do
    alternative = Sixpack.simple_participate('show-bieber', ['trolled', 'not-trolled'], "mike")
    Sixpack.simple_convert("show-bieber", "mike").should == "ok"
  end

  it "should return ok for multiple_converts" do
    alternative = Sixpack.simple_participate('show-bieber', ['trolled', 'not-trolled'], "mike")
    Sixpack.simple_convert("show-bieber", "mike").should == "ok"
    Sixpack.simple_convert("show-bieber", "mike").should == "ok"
  end

  it "should not return ok for simple_convert with new id" do
    Sixpack.simple_convert("show-bieber", "unknown_id").should == "failed"
  end

  it "should not return ok for simple_convert with new experiment" do
    alternative = Sixpack.simple_participate('show-bieber', ['trolled', 'not-trolled'], "mike")
    Sixpack.simple_convert("show-blieber", "mike").should == "failed"
  end

  it "should not allow bad experiment names" do
    expect {
      Sixpack.simple_participate('%%', ['trolled', 'not-trolled'], nil)
    }.to raise_error
  end

  it "should not allow bad alternatives names" do
    expect {
      Sixpack.simple_participate('show-bieber', ['trolled'], nil)
    }.to raise_error

    expect {
      Sixpack.simple_participate('show-bieber', ['trolled', '%%'], nil)
    }.to raise_error
  end

  it "should work without using the simple methods" do
    session = Sixpack::Session.new
    p session.client_id
    session.convert("testing")["status"].should == "failed"
    session.participate("testing", ["one", "two"], "two")["alternative"].should == "two"
    3.times do |n|
      p session.client_id
      session.participate("testing", ["one", "two"])["alternative"].should == "two"
    end
    session.convert("testing")["status"].should == "ok"

    old_client_id = session.client_id
    session.client_id = Sixpack::generate_client_id()

    p session.client_id
    session.convert("testing")["status"].should == "failed"
    session.participate("testing", ["one", "two"], "one")["alternative"].should == "one"
    3.times do |n|
      session.participate("testing", ["one", "two"])["alternative"].should == "one"
    end
    session.convert("testing")["status"].should == "ok"

    session.client_id = old_client_id

    p session.client_id
    3.times do |n|
      session.participate("testing", ["one", "two"])["alternative"].should == "two"
    end
  end
end
