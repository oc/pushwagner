$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'pushwagner'
require 'stringio'

require 'rspec'
require 'diff/lcs'

RSpec.configure do |config|
  config.before do
    ARGV.replace []
  end

  config.expect_with(:rspec) { |c| c.syntax = :expect }

  def config_root
    File.join(File.dirname(__FILE__), 'configs')
  end

end