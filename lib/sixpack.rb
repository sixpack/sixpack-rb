require "net/http"
require "json"

require "sixpack/version"

module Sixpack
  def self.simple_participate(experiment_name, alternatives, options = {})
    default_options = {:client_id => nil, :force => nil}
    options = default_options.merge(options)

    session = Session.new(options[:client_id])
    res = session.participate(experiment_name, alternatives, options)
    res["alternative"]
  end

  class Session
    def initialize(client_id = nil)
      if client_id.nil?
        @client_id = Sixpack::generate_client_id()
      else
        @client_id = client_id
      end
    end

    def participate(experiment_name, alternatives, options = {})
      default_options = {:force => nil}
      options = default_options.merge(options)

      params = {
        :client_id => @client_id,
        :experiment => experiment_name,
        :alternatives => alternatives
      }
      if !options[:force].nil? && alternatives.include?(options[:force])
        params[:force] = options[:force]
      end

      resp = self.get_response("/participate", params)
    end

    def get_response(endpoint, params)
      uri = URI('http://localhost:5000' + endpoint)
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(uri)
      JSON.parse(res.body)
    end
  end
end
