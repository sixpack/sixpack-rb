require 'redis'

require 'spec_helper'

RSpec.describe Sixpack do
  before(:each) do
    redis = Redis.new
    redis.flushdb
  end

  context 'configuration' do
    it 'should contain default base_url' do
      s = Sixpack::Session.new("foo")
      expect(s.base_url).to eq 'http://localhost:5000'
    end

    it 'should allow specifying the base_url in Session options' do
      s = Sixpack::Session.new("foo", base_url: 'http://0.0.0.0:5555')
      expect(s.base_url).to eq 'http://0.0.0.0:5555'
    end

    it 'should allow specifying the base_url in configuration block' do
      Sixpack.configure do |config|
        config.base_url = 'http://4.4.4.4'
      end
      s = Sixpack::Session.new("foo")
      expect(s.base_url).to eq 'http://4.4.4.4'
    end

    it 'session base_url should override configuration base_url' do
      Sixpack.configure do |config|
        config.base_url = 'http://4.4.4.4'
      end
      s = Sixpack::Session.new("foo", base_url: 'http://5.5.5.5')
      expect(s.base_url).to eq 'http://5.5.5.5'
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
