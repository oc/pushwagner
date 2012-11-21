require 'pushwagner/ext'
require 'pushwagner/maven'

module Pushwagner

  class Environment
    attr_reader :config
    attr_accessor :current, :version

    def initialize(opts = {})
      opts = HashWithIndifferentAccess.new(opts)

      config_file = opts[:config_file] || File.join(File.dirname(__FILE__), '/config/deploy.yml')
      @version = opts[:version]
      @current = opts[:environment] || 'development'

      @config = HashWithIndifferentAccess.new(YAML::load_file(config_file) || {})
    end

    def path_prefix
      config[:path_prefix] || '/srv/www'
    end

    def maven
      @maven = config[:maven] ? Maven.new(config[:maven], version) : {}
    end

    def maven?
      maven.any?
    end

    def static
      config[:static] || {}
    end

    def static?
      static.any?
    end

    def environments
      config[:environments] || {}
    end

    def environment
      environments[current] || {}
    end

    def hosts
      environment[:hosts] || []
    end

    def user
      environment[:user] || "nobody"
    end
  end
end