# Use colorize gem to color/fmt output
require 'colorize'

module Pushwagner
  def self.ok
    puts '[ ' + 'OK'.colorize(:green) + ' ]'
  end

  def self.severe(str)
    puts str.trunc(99).colorize(color: :red, mode: :bold)
  end

  def self.begin_info(str)
    print str.trunc(99).ljust(101, ".").colorize(mode: :bold)
  end

  def self.info(str)
    puts str.trunc(99).colorize(mode: :bold)
  end

  def self.warning(str)
    puts str.trunc(99).colorize(color: :yellow)
  end

end