require "net/http"
require "json"

require "uuid"

require "sixpack/version"

module Sixpack
  def self.simple_participate(experiment_name, alternatives, client_id, force=nil)
    session = Session.new(client_id)
    res = session.participate(experiment_name, alternatives, force)
    res["alternative"]
  end

  def self.simple_convert(experiment_name, client_id=nil)
    session = Session.new(client_id)
    session.convert(experiment_name)["status"]
  end

  def self.generate_client_id
    uuid = UUID.new
    uuid.generate
  end

  class Session
    def initialize(client_id=nil, options={})
      default_options = {:host => "localhost", :port => 5000}
      options = default_options.merge(options)
      @host = options[:host]
      @port = options[:port]

      if client_id.nil?
        @client_id = Sixpack::generate_client_id()
      else
        @client_id = client_id
      end
    end

    def participate(experiment_name, alternatives, force=nil)
      if !(experiment_name =~ /[a-z0-9][a-z0-9\-_ ]*/)
        raise ArgumentError, "Bad experiment_name"
      end

      if alternatives.length < 2
        raise ArgumentError, "Must specify at least 2 alternatives"
      end

      alternatives.each { |alt|
        if !(alt =~ /[a-z0-9][a-z0-9\-_ ]*/)
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

      self.get_response("/participate", params)
    end

    def convert(experiment_name)
      params = {
        :client_id => @client_id,
        :experiment => experiment_name
      }
      self.get_response("/convert", params)
    end

    def get_response(endpoint, params)
      uri = URI("http://#{@host}:#{@port}" + endpoint)
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(uri)
      if res.code == "500"
        {"status" => "failed", "response" => res.body}
      else
        JSON.parse(res.body)
      end
    end
  end
end
