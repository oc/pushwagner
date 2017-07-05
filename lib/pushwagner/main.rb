module Pushwagner

  class Main
    def initialize(opts = {})
      begin
        @environment = Pushwagner::Environment.new(opts)
      rescue => e
        Pushwagner.severe e.message
        exit
      end
    end

    def set_environment(env)
      @environment.current = env.to_s
    end

    def set_version(version)
      @environment.version = version.to_s
    end

    def deploy(opts = {})
      Pushwagner.info "Starting deployment to environment: #{@environment.current}"
      @environment.hosts.each { |h| Pushwagner.info "  - #{@environment.user}@#{h}" }
      
      pw_hooks = Hooks.new(@environment)
      pw_hooks.run(:before)

      Maven::Deployer.new(@environment, opts).deploy if @environment.maven?
      Static::Deployer.new(@environment, opts).deploy if @environment.static?

      pw_hooks.run(:after)
    end

  end

end