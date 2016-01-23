require "addressable/uri"
require "net/http"
require "json"
require "uri"
require "securerandom"

require "sixpack/version"
require "sixpack/configuration"

module Sixpack
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def generate_client_id
      SecureRandom.uuid
    end
  end

  class Session
    attr_accessor :client_id, :params, :base_url, :user, :password

    def initialize(client_id=nil, options={}, params={})
      # options supplied directly will override the configured options
      options = Sixpack.configuration.to_hash.merge(options)

      self.base_url = options[:base_url]
      self.user = options[:user]
      self.password = options[:password]

      self.params = params.dup
      self.params.delete_if { |_, v| v.nil? }

      if client_id.nil?
        self.client_id = Sixpack::generate_client_id
      else
        self.client_id = client_id
      end
    end

    def ip_address
      self.params[:ip_address]
    end

    def user_agent
      self.params[:user_agent]
    end

    def participate(experiment_name, alternatives, force=nil, kpi=nil)
      if !(experiment_name =~ /^[a-z0-9][a-z0-9\-_ ]*$/)
        raise ArgumentError, "Bad experiment_name, must be lowercase, start with an alphanumeric and contain alphanumerics, dashes and underscores"
      end

      if alternatives.length < 2
        raise ArgumentError, "Must specify at least 2 alternatives"
      end

      alternatives.each { |alt|
        if !(alt =~ /^[a-z0-9][a-z0-9\-_ ]*$/)
          raise ArgumentError, "Bad alternative name: #{alt}, must be lowercase, start with an alphanumeric and contain alphanumerics, dashes and underscores"
        end
      }

      params = {
        :client_id => self.client_id,
        :experiment => experiment_name,
        :alternatives => alternatives
      }
      params.merge!(kpi: kpi) if kpi
      if !force.nil? && alternatives.include?(force)
        return {"status" => "ok", "alternative" => {"name" => force}, "experiment" => {"version" => 0, "name" => experiment_name}, "client_id" => self.client_id}
      end

      res = self.get_response("/participate", params)
      # On server failure use control
      if res["status"] == "failed"
        res["alternative"] = {"name" => alternatives[0]}
      end
      res
    end

    def convert(experiment_name, kpi = nil)
      params = {
        :client_id => self.client_id,
        :experiment => experiment_name
      }
      params.merge!(kpi: kpi) if kpi
      self.get_response("/convert", params)
    end

    def get_response(endpoint, params)
      uri = URI.parse(self.base_url)
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http.open_timeout = 1.0
      http.read_timeout = 1.0
      query = Addressable::URI.form_encode(params.merge self.params)

      begin
        req = Net::HTTP::Get.new(uri.path + endpoint + "?" + query)
        # basic auth
        if self.user && self.password
          req.basic_auth(self.user, self.password)
        end
        res = http.request(req)
      rescue
        return {"status" => "failed", "error" => "http error"}
      end
      if res.code == "500"
        {"status" => "failed", "response" => res.body}
      else
        parse_response(res)
      end
    end

    def parse_response(res)
      JSON.parse(res.body)
    rescue JSON::ParserError
      {"status" => "failed", "response" => res.body}
    end
  end
end
