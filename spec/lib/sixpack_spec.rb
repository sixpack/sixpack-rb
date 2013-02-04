require 'spec_helper'

describe Sixpack do
  it "should return an alternative for simple_participate" do
    alternative = Sixpack.simple_participate('show-bieber', ['trolled', 'not-trolled'], :client_id => "mike")
    ['trolled', 'not-trolled'].should include(alternative)
  end
end
