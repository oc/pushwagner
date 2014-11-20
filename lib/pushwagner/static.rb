require 'net/ssh'
require 'net/scp'

module Pushwagner
  module Static
    class Deployer
      attr_reader :environment

      def initialize(environment, opts = {})
        @environment = environment
      end

      def deploy
        environment.static.each do |name, files|
          environment.hosts.each do |host|
            Net::SCP.start(host, environment.user) do |scp|
              dest = name.start_with?('/') ? name : "#{environment.path_prefix}/#{name}/"
              puts "Uploading files to #{host}:#{dest}/"
              files.each do |f|
                if File.exists?(f)
                  scp.upload!(f, dest, :recursive => File.directory?(f))
                else
                  puts "Warning: File #{f} does not exist"
                end
              end
            end
          end
        end
      end
      # EOC
    end
    # EOM
  end
end
