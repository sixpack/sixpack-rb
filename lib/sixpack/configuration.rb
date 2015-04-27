module Sixpack
  class Configuration
    attr_accessor :base_url, :user, :password

    def initialize
      @base_url = 'http://localhost:5000'
    end

    def to_hash
      config = {base_url: @base_url}
      config[:user] = @user unless @user.nil?
      config[:password] = @password unless @password.nil?
      config
    end
  end
end
