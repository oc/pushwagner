require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'pushwagner/environment'

describe Pushwagner::Maven do
  let(:cfg) {YAML::load_file(File.join(config_root, 'maven.yml'))['maven']}

  describe "#initialize" do
    it "requires a version" do
      expect { Pushwagner::Maven.new(cfg, nil) }.to raise_error(StandardError, "Deployment version for artifacts is required")
    end

    it "trickles the version down to artifacts" do
      m = Pushwagner::Maven.new(cfg, "1foo")
      expect(m.artifacts["some-api"].version).to eq("1foo")
    end

    it "allows stable versions on artifacts" do
      m = Pushwagner::Maven.new(cfg, "1bar")
      expect(m.artifacts["some-notifier"].version).to eq("1.0final")
    end

    it "returns nil-object maven when not configured" do
      m = Pushwagner::Maven.new({}, "1baz")
      expect(m.artifacts).to be_nil
      expect(m).to_not be_nil
    end

    describe "initialization of artifacts" do
      it "handles no artifacts" do
        cfg.delete('artifacts')
        m = Pushwagner::Maven.new(cfg, "1bar")
        expect(m.artifacts.size).to eq(0)
      end
      it "parses two artifacts" do
        m = Pushwagner::Maven.new(cfg, "1bar")
        expect(m.artifacts.size).to eq(2)
        expect(m.artifacts.keys.first).to eq("some-api")
        expect(m.artifacts.keys.last).to eq("some-notifier")
      end
    end

    describe "initialization of repositories" do
      it "requires snapshots repository" do
        cfg.delete('repositories')
        expect {Pushwagner::Maven.new(cfg, "1")}.to raise_error(StandardError)
      end
      it "requires snapshots repository" do
        cfg['repositories'].delete('snapshots')
        expect {Pushwagner::Maven.new(cfg, "1")}.to raise_error(StandardError)
      end
      it "requires releases repository" do
        cfg['repositories'].delete('releases')
        expect {Pushwagner::Maven.new(cfg, "1")}.to raise_error(StandardError)
      end
      it "parses repository" do
        m = Pushwagner::Maven.new(cfg, "1")
        expect(m.repository.snapshots_url).to eq("http://w00t.uppercase.no/nexus/content/repositories/snapshots")
        expect(m.repository.releases_url).to eq("http://w00t.uppercase.no/nexus/content/repositories/releases")
      end
    end
  end

  describe "repositories" do
    let(:settings) {IO.read(File.join(config_root, 'settings.xml'))}

    it "reads releases authentication from maven settings.xml" do
      m = Pushwagner::Maven.new(cfg, "1")
      m.repository.should_receive(:open).
          with(/.*settings.xml$/).
          and_return(settings)

      expect(m.repository.authentication).to eq("foo:bar")
    end

    it "reads snapshots authentication from maven settings.xml" do
      m = Pushwagner::Maven.new(cfg, "1")
      m.repository.should_receive(:open).
          with(/.*settings.xml$/).
          and_return(settings)

      expect(m.repository.authentication(true)).to eq("bar:baz")
    end

    let(:metadata) {IO.read(File.join(config_root, 'maven-metadata.xml'))}

    it "builds maven2-repo-style urls and retrieves metadata" do
      m = Pushwagner::Maven.new(cfg, "1")

      m.repository.should_receive(:authentication).and_return("")
      m.repository.should_receive(:open).and_return(metadata)

      snapshot = Pushwagner::Maven::Artifact.new("foo", "bar", "1.0-SNAPSHOT")
      expect(m.repository.absolute_url(snapshot)).to eq("http://w00t.uppercase.no/nexus/content/repositories/snapshots/bar/foo/1.0-SNAPSHOT/foo-1.0-20121114.152717-3.jar")
    end

    it "builds maven2-repo-style urls for release artifacts" do
      m = Pushwagner::Maven.new(cfg, "1")
      release = Pushwagner::Maven::Artifact.new("foo", "bar", "1.0")
      expect(m.repository.absolute_url(release)).to eq("http://w00t.uppercase.no/nexus/content/repositories/releases/bar/foo/1.0/foo-1.0.jar")
    end

  end

end
