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

end
