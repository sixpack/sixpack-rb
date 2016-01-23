require 'spec_helper'

RSpec.describe Sixpack do
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
    expect(['trolled', 'not-trolled']).to include(resp["alternative"]["name"])
  end

  it "should return the correct alternative for participate with force" do
    sess = Sixpack::Session.new("mike")
    alt = sess.participate('show-bieber', ['trolled', 'not-trolled'], "trolled")["alternative"]["name"]
    expect(alt).to eq "trolled"

    alt = sess.participate('show-bieber', ['trolled', 'not-trolled'], "not-trolled")["alternative"]["name"]
    expect(alt).to eq "not-trolled"
  end

  it "should allow ip and user agent to be passed to a session" do
    params = {:ip_address => '8.8.8.8', :user_agent => 'FirChromari'}
    session = Sixpack::Session.new('client_id', {}, params)
    expect(session.ip_address).to eq '8.8.8.8'
    expect(session.user_agent).to eq'FirChromari'
  end

  it "should auto generate a client_id" do
    sess = Sixpack::Session.new
    expect(sess.client_id.length).to eq 36
  end

  it "should not allow bad experiment names" do
    expect {
      sess = Sixpack::Session.new
      sess.participate('%%', ['trolled', 'not-trolled'], nil)
    }.to raise_error
  end

  it "should not try parse bad response body data" do
    sess = Sixpack::Session.new
    response = double(body: 'something unexpected', code: 200)
    allow_any_instance_of(Net::HTTP).to receive(:get).and_return(response)
    res = sess.participate('show-bieber', ['trolled', 'not-trolled'])
    expect(res["status"]).to eq('failed')
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
  
  context 'KPI' do

    it 'should convert w/out a KPI' do
      sess = Sixpack::Session.new
      sess.participate('show-bieber', ['trolled', 'not-trolled'])
      sess.convert('show-bieber')
    end

    it 'should allow setting a KPI when converting' do
      sess = Sixpack::Session.new
      sess.participate('show-bieber', ['trolled', 'not-trolled'])
      sess.convert('show-bieber', kpi = 'sales')
    end
  end

end
