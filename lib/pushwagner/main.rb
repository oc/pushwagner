module Pushwagner

  class Main
    def initialize(opts = {})
      @environment = Pushwagner::Environment.new(opts)
    end

    def set_environment(env)
      @environment.current = env.to_s
    end

    def set_version(version)
      @environment.version = version.to_s
    end

    def deploy(opts = {})
      puts "Deploying to #{@environment.current} environment:"
      @environment.hosts.each { |h| puts "  - #{@environment.user}@#{h}"}

      Maven::Deployer.new(@environment, opts).deploy if @environment.maven?
      Static::Deployer.new(@environment, opts).deploy if @environment.static?
    end

    def restart(opts = {})
      Supervisord::Restarter.new(@environment, opts).restart
    end
  end
end