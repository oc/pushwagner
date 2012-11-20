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
              puts "Uploading files to #{host}:#{environment.path_prefix}/#{name}/"
              files.each { |f| scp.upload!(f, "#{environment.path_prefix}/#{name}/") }
            end
          end
        end
      end
      # EOC
    end
    # EOM
  end
end
