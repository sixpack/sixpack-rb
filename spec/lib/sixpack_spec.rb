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
    response = double(body: JSON.generate({ 'alternative' => { 'name' => 'trolled' }}), code: 200)
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)

    sess = Sixpack::Session.new("mike")
    resp = sess.participate('show-bieber', ['trolled', 'not-trolled'])
    expect(['trolled', 'not-trolled']).to include(resp["alternative"]["name"])
  end

  it "should return the correct alternative for participate with force" do
    sess = Sixpack::Session.new("mike")

    response = double(body: JSON.generate({ "alternative" => { "name" => "trolled" }}), code: 200)
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)
    alt = sess.participate('show-bieber', ['trolled', 'not-trolled'], "trolled")["alternative"]["name"]
    expect(alt).to eq "trolled"

    response = double(body: JSON.generate({ "alternative" => { "name" => "not-trolled" }}), code: 200)
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)
    alt = sess.participate('show-bieber', ['trolled', 'not-trolled'], "not-trolled")["alternative"]["name"]
    expect(alt).to eq "not-trolled"
  end

  it 'should include the record_force in the outgoing request with force' do
    experiment_name = 'show-bieber'
    alternatives = ['trolled', 'not-trolled']

    sess = Sixpack::Session.new('123')
    expect(sess).to receive(:get_response)
                      .with('/participate',
                            client_id: '123',
                            experiment: experiment_name,
                            alternatives: alternatives,
                            force: 'trolled',
                            prefetch: false,
                            readonly: false,
                            record_force: true)
                      .and_return({})

    sess.participate(experiment_name, alternatives, 'trolled', nil, nil, true)
  end

  it 'should include the prefetch in the outgoing request' do
    experiment_name = 'experiment_name'
    alternatives = ['variant', 'control']

    sess = Sixpack::Session.new('client_id')
    expect(sess).to receive(:get_response)
                      .with('/participate',
                            client_id: 'client_id',
                            experiment: experiment_name,
                            alternatives: alternatives,
                            prefetch: true,
                            readonly: false)
                      .and_return({})

    sess.participate(experiment_name, alternatives, nil, nil, nil, nil, true)
  end

  it 'should include the readonly in the outgoing request' do
    experiment_name = 'experiment_name'
    alternatives = ['variant', 'control']

    sess = Sixpack::Session.new('client_id')
    expect(sess).to receive(:get_response)
                      .with('/participate',
                            client_id: 'client_id',
                            experiment: experiment_name,
                            alternatives: alternatives,
                            prefetch: false,
                            readonly: true)
                      .and_return({})

    sess.participate(experiment_name, alternatives, nil, nil, nil, nil, false, true)
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
    }.to raise_error(ArgumentError, 'Bad experiment_name, must be lowercase, start with an alphanumeric and contain alphanumerics, dashes and underscores')
  end

  it "should not allow force alternative that's not specified on alternatives list" do
    expect {
      sess = Sixpack::Session.new
      sess.participate('experiment', ['control', 'variant'], 'control2')
    }.to raise_error(ArgumentError, 'Cannot force an alternative that is not specified on alternatives argument')
  end

  it "should not try parse bad response body data" do
    sess = Sixpack::Session.new
    response = double(body: 'something unexpected', code: 200)
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)

    expect do
      sess.participate('show-bieber', ['trolled', 'not-trolled'])
    end.to raise_error(Sixpack::SixpackRequestFailed, 'Error parsing sixpack response: something unexpected')
  end

  it "should raise if sixpack returns internal server error response" do
    sess = Sixpack::Session.new
    response = double(body: '{}', code: 500)
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)

    expect do
      sess.participate('show-bieber', ['trolled', 'not-trolled'])
    end.to raise_error(Sixpack::SixpackRequestFailed, 'Sixpack internal server error')
  end

  it "should raise if sixpack call fails" do
    sess = Sixpack::Session.new
    allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(StandardError.new('Error message'))

    expect do
      sess.participate('show-bieber', ['trolled', 'not-trolled'])
    end.to raise_error(Sixpack::SixpackRequestFailed, 'Sixpack call error: Error message')
  end

  it "should not allow bad alternatives names" do
    expect {
      sess = Sixpack::Session.new
      sess.participate('show-bieber', ['trolled'], nil)
    }.to raise_error(ArgumentError, 'Must specify at least 2 alternatives')

    expect {
      sess = Sixpack::Session.new
      sess.participate('show-bieber', ['trolled', '%%'], nil)
    }.to raise_error(ArgumentError, 'Bad alternative name: %%, must be lowercase, start with an alphanumeric and contain alphanumerics, dashes and underscores')
  end

  context 'KPI' do
    let(:participate_response) { double(body: JSON.generate({ 'alternative' => { 'name' => 'trolled' }}), code: 200) }
    let(:convert_response) { double(body: '{}', code: 200) }

    it 'should convert w/out a KPI' do
      sess = Sixpack::Session.new

      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(participate_response)
      sess.participate('show-bieber', ['trolled', 'not-trolled'])

      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(convert_response)
      sess.convert('show-bieber')
    end

    it 'should allow setting a KPI when converting' do
      sess = Sixpack::Session.new

      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(participate_response)
      sess.participate('show-bieber', ['trolled', 'not-trolled'])

      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(convert_response)
      sess.convert('show-bieber', kpi = 'sales')
    end
  end

  context 'Traffic fraction' do
    let(:participate_response) { double(body: JSON.generate({ 'alternative' => { 'name' => 'trolled' }}), code: 200) }

    before do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(participate_response)
    end

    it 'should not allow traffic fraction greater than 1' do
      expect {
        sess = Sixpack::Session.new
        sess.participate('show-bieber', ['trolled', 'not-trolled'], nil, nil, '1.1')
      }.to raise_error(ArgumentError, 'Invalid traffic fraction, must be between 0 and 1')
    end

    it 'should not allow traffic fraction less than 0' do
      expect {
        sess = Sixpack::Session.new
        sess.participate('show-bieber', ['trolled', 'not-trolled'], nil, nil, '-1')
      }.to raise_error(ArgumentError, 'Invalid traffic fraction, must be between 0 and 1')
    end

    it 'should allow traffic fraction when valid value is passed' do
      expect {
        sess = Sixpack::Session.new
        sess.participate('show-bieber', ['trolled', 'not-trolled'], nil, nil, '0.5')
      }.to_not raise_error
    end

    it 'should allow no traffic_fraction to be passed' do
      expect {
        sess = Sixpack::Session.new
        sess.participate('show-bieber', ['trolled', 'not-trolled'])
      }.to_not raise_error
    end

    it 'should include the fraction value in the outgoing request' do
      experiment_name = 'show-bieber'
      alternatives = ['trolled', 'not-trolled']

      sess = Sixpack::Session.new('123')
      expect(sess).to receive(:get_response)
        .with('/participate',
              client_id: '123',
              experiment: experiment_name,
              alternatives: alternatives,
              traffic_fraction: '0.5',
              prefetch: false,
              readonly: false)
        .and_return({})

      sess.participate(experiment_name, alternatives, nil, nil, '0.5')
    end
  end
end
