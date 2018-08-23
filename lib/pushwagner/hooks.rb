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
    
    attr_reader :environment, :before, :after, :sudo

    def initialize(env, remote)
      @environment = env

      @before = remote['before'] || []
      @after = remote['after'] || []
    end

    def run(target)
      ssh_exec(method(target).call)
    end

    def gets_sudo_passwd
      if ENV['PUSHWAGNER_SUDO']
        @sudo = ENV['PUSHWAGNER_SUDO']
      elsif @sudo.nil?
        puts
        Pushwagner.severe  "<<< WARNING: this operation requires privileges >>>"
        Pushwagner.warning "Enter Ctrl+C to abort."
        print "Enter sudo-passwd: "

        begin
          system 'stty -echo'
        rescue
          # windoz
        end
        @sudo = STDIN.gets.chomp
        puts
        begin
          system 'stty echo'
        rescue
          # windoz
        end
      end
      @sudo
    end

    def ssh_exec(cmds)
      environment.hosts.each do |host|
        cmds.each do |cmd|
          # Run each cmd in a separate 'transaction'
          Pushwagner.begin_info "Executing `#{cmd}` on #{host}"

          Net::SSH.start(host, environment.user) do |ssh|
            ssh.open_channel do |ch|

              ch.request_pty do |pty_ch, success|
                raise "FATAL: could not execute #{cmd}" unless success

                puts

                ch.exec("#{cmd}") do |ch, success_exec|
                  raise "FATAL: failed on execution of #{cmd}" unless success_exec  
                end

                ch.on_extended_data do |data_ch, type, data|
                  if data =~ /\[sudo\] password/i
                    gets_sudo_passwd unless sudo
                    ch.send_data("#{sudo}\n")
                  elsif type == :stderr
                    print "ERROR: #{data}"
                  else
                    print data
                  end
                end
              end
            end

            ssh.loop
          end

          Pushwagner.ok
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
        Pushwagner.info "Executing `#{cmd}` locally..."

        system("#{cmd}")

      end
    end

  end
end

