require 'net/https'
require 'net/ssh'
require 'net/scp'
require 'open-uri'
require 'nokogiri'

module Pushwagner
  class Maven

    attr_reader :repository, :artifacts
    def initialize(maven, version)
      required("Need maven configuration") unless maven

      if version && !version.empty?
        @version = version
      else
        required("Deployment version for artifacts is required")
      end

      @repository = Repository.new(maven['repositories'])
      @artifacts = Hash[(maven['artifacts'] || required("Requires at least one maven artifact")).map { |k,h| [k, Artifact.new(h['artifact_id'], h['group_id'], h['version'] || version)] }]

      (artifacts && repository) || required("Could not initialize maven configuration")
    end

    def required(msg)
      raise StandardError.new(msg)
    end

    def any?
      artifacts && repository
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

    def to_s
      "#{group_id}:#{artifact_id}:#{version}"
    end

  end

  class Maven::Repository
    attr_reader :snapshots_url
    attr_reader :releases_url

    def initialize(repositories)
      required(repositories, "repositories configuration required")
      required(repositories['snapshots'], "snapshots repository required")
      required(repositories['releases'], "releases repository required")

      @snapshots_url = repositories['snapshots']
      @releases_url = repositories['releases']
    end

    def absolute_url(artifact)
      if artifact.snapshot?
        doc = Nokogiri::XML(open(URI.parse("#{snapshots_url}/#{artifact.base_path}/maven-metadata.xml"), :http_basic_authentication => authentication(true).split(":")))
        snapshot_version = doc.xpath("//metadata/versioning/snapshotVersions/snapshotVersion/value/text()").first.content
        return "#{snapshots_url}/#{artifact.base_path}/#{artifact.artifact_id}-#{snapshot_version}.jar"
      end

      "#{releases_url}/#{artifact.jar_path}"
    end

    def authentication(snapshots = false)
      @settings_file ||= ENV['M2_HOME'] ? "#{ENV['M2_HOME']}/conf/settings.xml" : "#{ENV['HOME']}/.m2/settings.xml"

      if File.exists?(@settings_file)
        Nokogiri::XML(open(@settings_file)).css("settings servers server").each do |n|
          return "#{n.css("username").text}:#{n.css("password").text}" if n.css("id").text == (snapshots ? 'snapshots' : 'releases')
        end
      end
      ""
    end

    def required(exp, message)
      raise StandardError.new(message) unless exp
    end

  end

  #
  # Deployer strategy for maven repos (wip).
  #
  class Maven::Deployer

    attr_reader :environment, :artifacts, :repository

    def initialize(env, opts = {})
      @environment = env
      # TODO: nil-object instead?
      @artifacts = env.maven? ? env.maven.artifacts : {}
      @repository = env.maven? ? env.maven.repository : nil
    end

    def deploy
      artifacts.each do |name, artifact|
        environment.hosts.each do |host|
          Pushwagner.info "Deploying #{name}, #{artifact} to #{host}"

          mark_previous(name, host)
          pull_artifact(name, artifact, host)
          mark_new(name, artifact, host)

        end
      end
      true # false if failed
    end

    protected

    def pull_artifact(name, artifact, host)
      Net::SSH.start(host, environment.user) do |ssh|
        Pushwagner.begin_info "Pulling #{repository.absolute_url(artifact)} to #{host}:#{environment.path_prefix}/#{artifact.jar_name}"
        ssh.exec("curl --user '#{repository.authentication(artifact.snapshot?)}' #{repository.absolute_url(artifact)} > #{environment.path_prefix}/#{name}/#{artifact.jar_name}")
        Pushwagner.ok
      end
    end

    def mark_previous(name, host)
      Net::SSH.start(host, environment.user) do |ssh|
        Pushwagner.begin_info "Marking previous release on #{host}"
        ssh.exec("cp -P #{environment.path_prefix}/#{name}/#{name}.jar #{environment.path_prefix}/#{name}/#{name}.previous.jar")
        Pushwagner.ok
      end
    end

    def mark_new(name, artifact, host)
      Net::SSH.start(host, environment.user) do |ssh|
        Pushwagner.begin_info "Marking #{artifact.jar_name} as current on #{host}"
        ssh.exec("ln -sf #{environment.path_prefix}/#{name}/#{artifact.jar_name} #{environment.path_prefix}/#{name}/#{name}.jar")
        Pushwagner.ok
      end
    end

  end
  ##
end