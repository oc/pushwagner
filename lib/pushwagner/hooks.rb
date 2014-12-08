require 'net/https'
require 'net/ssh'
require 'net/scp'
require 'open-uri'
require 'nokogiri'

module Pushwagner

  #
  # Deployer strategy for maven repos (wip).
  #
  class Hooks

    attr_reader :remote, :local

    def initialize(env)
      raise "Invalid environment" unless env
      default_cfg = { before: [], after: [] }
      @local = Hooks::Local.new(env, env.hooks['local'] || default_cfg)
      @remote = Hooks::Remote.new(env, env.hooks['remote'] || default_cfg)
    end

    def run(target)
      if target == :before
        local.run(target)
        remote.run(target)
      elsif target == :after
        local.run(target)
        remote.run(target)
      end
    end

  end

  class Hooks::Remote
    
    attr_reader :environment, :before, :after

    def initialize(env, remote)
      @environment = env

      @before = remote['before'] || []
      @after = remote['after'] || []
    end

    def run(target)
      ssh_exec(method(target).call)
    end


    def ssh_exec(cmds)
      environment.hosts.each do |host|
        cmds.each do |cmd|
          # Run each cmd in a separate 'transaction'
          Net::SSH.start(host, environment.user) do |ssh|
            print "Executing on #{host.trunc(25)}:".ljust(40)
            print "`#{cmd.trunc(25)}`".ljust(30)
            ssh.exec("#{cmd}")
            puts '[ OK ]'
          end
        end
      end
    end

  end
  
  class Hooks::Local
    
    attr_reader :environment, :before, :after

    def initialize(env, local)
      @environment = env
      @before = local['before'] || []
      @after = local['after'] || []
    end

    def run(target)
      local_exec(method(target).call)
    end

    private
    def local_exec(cmds)
      cmds.each do |cmd|
        print "Executing locally:".ljust(40)
        print "`#{cmd.trunc(25)}`".ljust(30)
        system("#{cmd}")
        puts '[ OK ]'
      end
    end

  end
end