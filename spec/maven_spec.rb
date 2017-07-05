require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'pushwagner/environment'

describe Pushwagner::Maven do
  let(:cfg) {YAML::load_file(File.join(config_root, 'maven.yml'))['maven']}

  describe "#initialize" do
    it "requires a version" do
      expect { Pushwagner::Maven.new(cfg, nil) }.to raise_error(StandardError, "Deployment version for artifacts is required")
    end

    it "requires valid configuration" do
      expect{Pushwagner::Maven.new(nil, "1baz")}.to raise_error(StandardError, "Need maven configuration")
    end

    it "requires valid repositories configuration" do
      expect{Pushwagner::Maven.new({}, "1baz")}.to raise_error(StandardError, "repositories configuration required")
    end

    it "trickles the version down to artifacts" do
      m = Pushwagner::Maven.new(cfg, "1foo")
      expect(m.artifacts["some-api"].version).to eq("1foo")
    end

    it "allows stable versions on artifacts" do
      m = Pushwagner::Maven.new(cfg, "1bar")
      expect(m.artifacts["some-notifier"].version).to eq("1.0final")
    end

    describe "artifacts" do
      it "requires at least one artifact" do
        cfg.delete('artifacts')
        expect {Pushwagner::Maven.new(cfg, "1bar")}.to raise_error(StandardError, "Requires at least one maven artifact")
      end
      it "parses two artifacts" do
        m = Pushwagner::Maven.new(cfg, "1bar")
        expect(m.artifacts.size).to eq(2)
        expect(m.artifacts.keys).to include("some-api")
        expect(m.artifacts.keys).to include("some-notifier")
      end
    end

    describe "repositories" do
      it "requires repositories configuration element" do
        cfg.delete('repositories')
        expect {Pushwagner::Maven.new(cfg, "1")}.to raise_error(StandardError, /repositories configuration required/)
      end
      it "requires 'snapshots' repository" do
        cfg['repositories'].delete('snapshots')
        expect {Pushwagner::Maven.new(cfg, "1")}.to raise_error(StandardError, /snapshots repository required/)
      end
      it "requires 'releases' repository" do
        cfg['repositories'].delete('releases')
        expect {Pushwagner::Maven.new(cfg, "1")}.to raise_error(StandardError, /releases repository required/)
      end
      it "parses repositories" do
        m = Pushwagner::Maven.new(cfg, "1")
        expect(m.repository.snapshots_url).to eq("http://w00t.uppercase.no/nexus/content/repositories/snapshots")
        expect(m.repository.releases_url).to eq("http://w00t.uppercase.no/nexus/content/repositories/releases")
      end
    end
  end

  describe "repository authentication" do
    let(:settings) {IO.read(File.join(config_root, 'settings.xml'))}

    it "reads releases authentication from maven settings.xml" do
      m = Pushwagner::Maven.new(cfg, "1")
      expect(m.repository).to receive(:open).
          with(/.*settings.xml$/).
          and_return(settings)

      expect(m.repository.authentication).to eq("foo:bar")
    end

    it "reads snapshots authentication from maven settings.xml" do
      m = Pushwagner::Maven.new(cfg, "1")
      expect(m.repository).to receive(:open).
          with(/.*settings.xml$/).
          and_return(settings)

      expect(m.repository.authentication(true)).to eq("bar:baz")
    end
  end
  describe "maven2-style repo support" do
    let(:metadata) {IO.read(File.join(config_root, 'maven-metadata.xml'))}

    it "builds maven2-repo-style urls and retrieves metadata" do
      m = Pushwagner::Maven.new(cfg, "1")

      expect(m.repository).to receive(:authentication).and_return("")
      expect(m.repository).to receive(:open).and_return(metadata)

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
