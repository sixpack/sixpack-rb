require "net/http"
require "json"

require "sixpack/version"

module Sixpack
  def self.simple_participate(experiment_name, alternatives, options={})
    default_options = {:client_id => nil, :force => nil}
    options = default_options.merge(options)

    session = Session.new(options[:client_id])
    res = session.participate(experiment_name, alternatives, options[:force])
    res["alternative"]
  end

  def self.simple_convert(experiment_name, client_id=nil)
    session = Session.new(client_id)
    session.convert(experiment_name)["status"]
  end

  class Session
    def initialize(client_id = nil)
      if client_id.nil?
        @client_id = Sixpack::generate_client_id()
      else
        @client_id = client_id
      end
    end

    def participate(experiment_name, alternatives, force=nil)
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
      uri = URI('http://localhost:5000' + endpoint)
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
