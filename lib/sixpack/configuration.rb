module Sixpack
  class Configuration
    attr_accessor :base_url

    def initialize
      @base_url = 'http://localhost:5000'
    end

    def to_hash
      {base_url: @base_url}
    end
  end
end
