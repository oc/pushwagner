module Pushwagner

  class Environment
    attr_reader :config
    attr_writer :current
    attr_writer :version

    def initialize(opts = {})
      config_file = opts['config_file'] || File.join(File.dirname(__FILE__), '/config/deploy.yml')

      @current = opts['environment'] || 'development'
      @config = YAML::load_file(config_file)
    end

    def path_prefix
      config['path_prefix'] || '/srv/www'
    end

    def environments
      config['environments']
    end

    def maven
      @maven = Maven.new(config['maven'], version)
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

    def environment
      environments[current]
    end

    def hosts
      environment['hosts']
    end

    def user
      environment['user']
    end
  end
end