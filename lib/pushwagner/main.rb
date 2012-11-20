module Pushwagner

  class Main
    def initialize(opts = {})
      @environment = Environment.new(opts)
    end

    def set_environment(env)
      @environment.current = env.to_s
    end

    def set_version(version)
      @environment.version = version
    end

    def deploy(opts = {})
      Maven::Deployer.new(@environment, opts).deploy
      Static::Deployer.new(@environment, opts).deploy
    end

    def restart(opts = {})
      Supervisord::Restarter.new(@environment, opts).restart
    end
  end
end