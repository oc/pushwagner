require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'pushwagner/environment'

describe Pushwagner::Environment do
  describe "#initialize" do
    it "requires config_file" do
      expect { Pushwagner::Environment.new('config_file' => File.join(config_root, 'nonexisting.yml'))}.to raise_error(RuntimeError, /Couldn't find config file in locations: (.*)/)
    end

    it "supports config_file" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'full.yml'))
      expect(env.path_prefix).to eq("/full/path")
    end

    it "supports :config_file" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'static.yml'))
      expect(env.path_prefix).to eq("/static/path")
    end

    it "supports :version" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'full.yml'), :version => "1.3.3.7")
      expect(env.version).to eq("1.3.3.7")
    end
  end
  describe "maven artifacts" do
    it "requires a version" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'maven.yml'))
      expect { env.maven }.to raise_error(StandardError, "Deployment version for artifacts is required")
    end

    it "returns empty hash when not configured" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'static.yml'), :version => "1foo" )
      expect(env.maven?).to be false
      expect(env.maven).to eq({})
    end
  end
  describe "static files" do
    it "returns empty hash when not configured" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'maven.yml'), :version => "1foo" )
      expect(env.static?).to be false
      expect(env.static).to eq({})
    end
    it "parses to a hash of files" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'static.yml'))
      expect(env.static).to eq({'blah.uppercase.no' => ['index.htm', 'static']})
    end
  end
  describe "environments" do
    it "returns all environments" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'full.yml'), :version => "1foo" )
      expect(env.environments.size).to eq(2)
    end
    describe "environment" do
      it "returns empty environment if it doesn't exist" do
        env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'full.yml'), :version => "1foo" )
        expect(env.environment).to eq({})
      end
      it "returns environment if it exists" do
        env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'full.yml'), :version => "1foo", :environment => "staging")
        expect(env.environment).to eq({'hosts' => ["staging.uppercase.no"], 'user' => "www-data"})
      end
      describe "hosts" do
        it "returns empty list if it doesn't exist" do
          env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'empty.yml'), :version => "1foo" )
          expect(env.hosts).to eq([])
        end
        it "returns environment if it exists" do
          env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'full.yml'), :version => "1foo", :environment => "staging")
          expect(env.environment).to eq({'hosts' => ["staging.uppercase.no"], 'user' => "www-data"})
        end
      end
    end
  end
end
