require 'redis'

require 'spec_helper'

describe Sixpack do
  before(:each) do
    redis = Redis.new
    redis.keys("*").each do |k|
      redis.del(k)
    end
  end

  it "should return an alternative for participate" do
    sess = Sixpack::Session.new("mike")
    resp = sess.participate('show-bieber', ['trolled', 'not-trolled'])
    ['trolled', 'not-trolled'].should include(resp["alternative"]["name"])
  end

  it "should return the correct alternative for participate with force" do
    sess = Sixpack::Session.new("mike")
    alt = sess.participate('show-bieber', ['trolled', 'not-trolled'], "trolled")["alternative"]["name"]
    alt.should == "trolled"

    alternative = sess.participate('show-bieber', ['trolled', 'not-trolled'], "not-trolled")["alternative"]["name"]
    alternative.should == "not-trolled"
  end

  it "should allow ip and user agent to be passed to a session" do
    params = {:ip_address => '8.8.8.8', :user_agent => 'FirChromari'}
    session = Sixpack::Session.new('client_id', {}, params)
    session.ip_address.should == '8.8.8.8'
    session.user_agent.should == 'FirChromari'
  end

  it "should auto generate a client_id" do
    sess = Sixpack::Session.new
    sess.client_id.length.should == 36
  end

  it "should return ok for convert" do
    sess = Sixpack::Session.new("mike")
    alternative = sess.participate('show-bieber', ['trolled', 'not-trolled'])
    sess.convert("show-bieber")["status"].should == "ok"
  end

  it "should return ok for multiple_converts" do
    sess = Sixpack::Session.new("mike")
    sess.participate('show-bieber', ['trolled', 'not-trolled'])
    sess.convert("show-bieber")["status"].should == "ok"
    sess.convert("show-bieber")["status"].should == "ok"
  end

  it "should not return ok for convert with new id" do
    sess = Sixpack::Session.new("unknown_id")
    sess.convert("show-bieber")["status"].should == "failed"
  end

  it "should not return ok for convert with new experiment" do
    sess = Sixpack::Session.new
    sess.convert("show-blieber")['status'].should == "failed"
  end

  it "should not allow bad experiment names" do
    expect {
      sess = Sixpack::Session.new
      sess.participate('%%', ['trolled', 'not-trolled'], nil)
    }.to raise_error
  end

  it "should not allow bad alternatives names" do
    expect {
      sess = Sixpack::Session.new
      sess.participate('show-bieber', ['trolled'], nil)
    }.to raise_error

    expect {
      sess = Sixpack::Session.new
      sess.participate('show-bieber', ['trolled', '%%'], nil)
    }.to raise_error
  end

  it "should work" do
    session = Sixpack::Session.new
    session.convert("testing")["status"].should == "failed"
    alt_one = session.participate("testing", ["one", "two"])["alternative"]
    3.times do |n|
      session.participate("testing", ["one", "two"])["alternative"].should == alt_one
    end
    session.convert("testing")["status"].should == "ok"

    old_client_id = session.client_id
    session.client_id = Sixpack::generate_client_id()
    session.convert("testing")["status"].should == "failed"
    alt_two = session.participate("testing", ["one", "two"])["alternative"]
    3.times do |n|
      session.participate("testing", ["one", "two"])["alternative"].should == alt_two
    end
    session.convert("testing")["status"].should == "ok"

    session = Sixpack::Session.new old_client_id
    3.times do |n|
      session.participate("testing", ["one", "two"])["alternative"].should == alt_one
    end
  end
end
