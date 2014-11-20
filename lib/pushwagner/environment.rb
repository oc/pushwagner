require 'pushwagner/ext'
require 'pushwagner/maven'
require 'yaml'

module Pushwagner

  class Environment
    attr_reader :config
    attr_accessor :current, :version

    def initialize(opts = {})
      opts = HashWithIndifferentAccess.new(opts)

      config_file = look_for_config_file(opts[:config_file])

      @version = opts[:version] && opts[:version].to_s
      @current = opts[:environment] || 'development'

      @config = HashWithIndifferentAccess.new(YAML::load_file(config_file) || {})
    end

    def path_prefix
      config['path_prefix'] || '/'
    end

    def maven
      @maven = (config['maven'] ? Maven.new(config['maven'], version) : {})
    end

    def maven?
      maven.any?
    end

    def static
      config['static'] || {}
    end

    def static?
      static.any?
    end

    def environments
      config['environments'] || {}
    end

    def environment
      environments[current] || {}
    end

    def hosts
      environment['hosts'] || []
    end

    def user
      environment['user'] || "nobody"
    end

    private
    def look_for_config_file(file)
      locations = [file, './deploy.yml', './.pw.yml', './config/deploy.yml']

      locations.each do |location|
        return location if File.exist? location
        cf = File.join(File.dirname(__FILE__), location) # i.e rake/thor.
        return cf if File.exist? cf
      end
      raise "Couldn't find config file in locations: #{locations.join(', ')}"
    end
  end
end
