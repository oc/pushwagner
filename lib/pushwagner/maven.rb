require 'net/https'
require 'net/ssh'
require 'net/scp'
require 'open-uri'
require 'nokogiri'

module Pushwagner
  class Maven

    attr_reader :repository, :artifacts

    # maven:
    #  repositories:
    #    releases:  http://admin.uppercase.no/nexus/content/repositories/releases
    #    snapshots: http://admin.uppercase.no/nexus/content/repositories/snapshots
    #  artifacts:
    #    hubble-api:
    #      group_id:    hubble
    #      artifact_id: hubble-api
    #    hubble-notifier:
    #      group_id:    hubble
    #      artifact_id: hubble-notifier
    #    hubble-notifier1:
    #      group_id:    hubble
    #      artifact_id: hubble-notifier
    #      version:     1.0
    def initialize(maven, version)
      @version = version || required("Deployment version for artifacts is required")
      @repository = Repository.new(maven['repositories'])
      @artifacts = Hash[maven['artifacts'].map { |k,h| [k, Artifact.new(h['artifact_id'], h['group_id'], h['version'] || version)] }]
    end

    def self.required(msg)
      raise StandardError.new(msg)
    end
  end

  class Maven::Artifact
    attr_reader :artifact_id, :group_id, :version
    def initialize(artifact_id, group_id, version)
      @artifact_id = artifact_id
      @group_id = group_id
      @version = version
    end

    def base_path
      "#{group_id.gsub('.', '/')}/#{artifact_id.gsub('.', '/')}/#{version}"
    end

    def jar_name
      "#{artifact_id}-#{version}.jar"
    end

    def jar_path
      "#{base_path}/#{jar_name}"
    end

    def snapshot?
      version.downcase =~ /snapshot/
    end

  end

  # TODO: model this better - should probably support other repo id's.
  # TODO2: validate file exists (HEAD)
  # TODO3: clean up
  # TODO4: Use REXML instead of nokogiri?
  class Maven::Repository
    attr_reader :snapshots_url
    attr_reader :releases_url

    def initialize(repositories)
      @snapshots_url = repositories['snapshots']
      @releases_url = repositories['releases']
    end

    def absolute_url(artifact)
      if artifact.snapshot?
        doc = Nokogiri::XML(open(URI.parse("#{snapshots_url}/#{artifact.base_path}/maven-metadata.xml"), :http_basic_authentication => authentication(false)))
        snapshot_version = doc.xpath("//metadata/versioning/snapshotVersions/snapshotVersion/value/text()").first.content
        return "#{snapshots_url}/#{artifact.base_path}/#{artifact.artifact_id}-#{snapshot_version}.jar"
      end

      "#{releases_url}/#{artifact.jar_path}"
    end

    def authentication(snapshots = false)
      @settings_file ||= ENV['M2_HOME'] ? "#{ENV['M2_HOME']}/conf/settings.xml" : "#{ENV['HOME']}/.m2/settings.xml"

      if File.exists?(@settings_file)
        Nokogiri::XML(open(settings_file)).css("settings servers server").each do |n|
          return "#{n.css("username").text}:#{n.css("password").text}" if n.css("id").text == snapshots ? 'snapshots' : 'releases'
        end
      end
      ""
    end
  end

  #
  # Deployer strategy for maven repos (wip).
  #
  class Maven::Deployer

    attr_reader :environment, :artifacts, :repository

    def initialize(env, opts = {})
      @environment = env
      @artifacts = env.maven.artifacts
      @repository = env.maven.repository
    end

    def deploy
      artifacts.each do |name, artifact|
        environment.hosts.each do |host|
          mark_previous(name, artifact, host)
          pull_artifact(name, artifact, host)
          mark_new(name, artifact, host)
        end
      end
      true # false if failed
    end

    protected

    def pull_artifact(name, artifact, host)
      Net::SSH.start(host, environment.user) do |ssh|
        puts "Pulling #{repository.absolute_url(artifact)} to #{host}:#{environment.path_prefix}/#{artifact.jar_name}..."
        ssh.exec("curl --user '#{repository.authentication(artifact.snapshot?)}' #{repository.absolute_url(artifact)} > #{environment.path_prefix}/#{artifact.jar_name}")
      end
    end

    def mark_previous(name, host)
      Net::SSH.start(host, user) do |ssh|
        puts "Marking previous release on #{host}..."
        ssh.exec("cp -P #{environment.path_prefix}/#{name}.jar #{environment.path_prefix}/#{name}.previous.jar")
      end
    end

    def mark_new(name, artifact, host)
      Net::SSH.start(host, user) do |ssh|
        cwd = deploy_path(app_name)
        puts "Marking #{artifact.jar_name} as current on #{host}..."
        ssh.exec("ln -sf #{environment.path_prefix}/#{artifact.jar_name} #{environment.path_prefix}/#{name}.jar")
      end
    end

  end
  ##
end