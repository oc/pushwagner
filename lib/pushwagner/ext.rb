# Use colorize gem to color/fmt output
require 'colorize'

class String
  def trunc(sz)
    str = self.strip
    if str.length == sz
      str
    elsif self.length > (sz - 2)
      "#{str[0, sz - 2]}.."
    else
      str
    end
  end
end

module Pushwagner
  # Shamefully copied from ActiveSupport
  class HashWithIndifferentAccess < ::Hash
    def initialize(hash={})
      super()
      hash.each do |key, value|
        self[convert_key(key)] = value
      end
    end

    def [](key)
      super(convert_key(key))
    end

    def []=(key, value)
      super(convert_key(key), value)
    end

    def delete(key)
      super(convert_key(key))
    end

    def values_at(*indices)
      indices.collect { |key| self[convert_key(key)] }
    end

    def merge(other)
      dup.merge!(other)
    end

    def merge!(other)
      other.each do |key, value|
        self[convert_key(key)] = value
      end
      self
    end

    def to_hash
      Hash.new(default).merge!(self)
    end

    protected
    def convert_key(key)
      key.is_a?(Symbol) ? key.to_s : key
    end

    def method_missing(method, *args, &block)
      method = method.to_s
      if method =~ /^(\w+)\?$/
        if args.empty?
          !!self[$1]
        else
          self[$1] == args.first
        end
      else
        self[method]
      end
    end
  end
end