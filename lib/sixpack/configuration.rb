module Sixpack
  class Configuration
    attr_accessor :base_url, :user, :password, :read_timeout

    def initialize
      @base_url = 'http://localhost:5000'
      @read_timeout = 1.0
    end

    def to_hash
      config = { base_url: @base_url, read_timeout: @read_timeout }
      config[:user] = @user unless @user.nil?
      config[:password] = @password unless @password.nil?
      config
    end
  end
end
