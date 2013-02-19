require "addressable/uri"
require "net/http"
require "json"
require "uuid"
require "uri"

require "sixpack/version"

module Sixpack
  extend self

  attr_accessor :base_url

  @base_url = "http://localhost:5000"

  def simple_participate(experiment_name, alternatives, client_id=nil, force=nil)
    session = Session.new(client_id)
    res = session.participate(experiment_name, alternatives, force)
    res["alternative"]["name"]
  end

  def simple_convert(experiment_name, client_id)
    session = Session.new(client_id)
    session.convert(experiment_name)["status"]
  end

  def generate_client_id
    uuid = UUID.new
    uuid.generate
  end

  class Session
    attr_accessor :base_url, :client_id, :ip_address, :user_agent

    def initialize(client_id=nil, options={}, params={})
      default_options = {:base_url => Sixpack.base_url}
      options = default_options.merge(options)
      @base_url = options[:base_url]

      default_params = {:ip_address => nil, :user_agent => :nil}
      params = default_params.merge(params)

      @ip_address = params[:ip_address]
      @user_agent = params[:user_agent]

      if client_id.nil?
        @client_id = Sixpack::generate_client_id()
      else
        @client_id = client_id
      end
    end

    def participate(experiment_name, alternatives, force=nil)
      if !(experiment_name =~ /^[a-z0-9][a-z0-9\-_ ]*$/)
        raise ArgumentError, "Bad experiment_name"
      end

      if alternatives.length < 2
        raise ArgumentError, "Must specify at least 2 alternatives"
      end

      alternatives.each { |alt|
        if !(alt =~ /^[a-z0-9][a-z0-9\-_ ]*$/)
          raise ArgumentError, "Bad alternative name: #{alt}"
        end
      }

      params = {
        :client_id => @client_id,
        :experiment => experiment_name,
        :alternatives => alternatives
      }
      if !force.nil? && alternatives.include?(force)
        params[:force] = force
      end

      res = self.get_response("/participate", params)
      # On server failure use control
      if res["status"] == "failed"
        res["alternative"] = {"name" => alternatives[0]}
      end
      res
    end

    def convert(experiment_name)
      params = {
        :client_id => @client_id,
        :experiment => experiment_name
      }
      self.get_response("/convert", params)
    end

    def build_params(params)
      unless @ip_address.nil?
        params[:ip_address] = @ip_address
      end
      unless @user_agent.nil?
        params[:user_agent] = @user_agent
      end
      params
    end

    def get_response(endpoint, params)
      uri = URI.parse(@base_url)
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http.open_timeout = 0.25
      http.read_timeout = 0.25
      query = Addressable::URI.form_encode(self.build_params(params))

      begin
        res = http.start do |http|
          http.get(uri.path + endpoint + "?" + query)
        end
      rescue
        return {"status" => "failed", "error" => "http error"}
      end
      if res.code == "500"
        {"status" => "failed", "response" => res.body}
      else
        JSON.parse(res.body)
      end
    end
  end
end
