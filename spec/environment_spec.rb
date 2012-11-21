require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'pushwagner/environment'

describe Pushwagner::Environment do
  describe "#initialize" do
    it "requires config_file" do
      expect { Pushwagner::Environment.new('config_file' => File.join(config_root, 'nonexisting.yml'))}.to raise_error
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
  describe "#maven" do
    it "requires a version" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'maven.yml'))
      expect { env.maven }.to raise_error(StandardError, "Deployment version for artifacts is required")
    end

    it "returns empty hash when not configured" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'static.yml'), :version => "1foo" )
      expect(env.maven?).to be_false
      expect(env.maven).to eq({})
    end
  end
  describe "#static" do
    it "returns empty hash when not configured" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'maven.yml'), :version => "1foo" )
      expect(env.static?).to be_false
      expect(env.static).to eq({})
    end
    it "is a hash with files" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'static.yml'))
      expect(env.static).to eq({'diakonhjemmet.uppercase.no' => ['index.htm', 'static']})
    end
  end
  describe "#environments" do
    it "returns all environments" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'full.yml'), :version => "1foo" )
      expect(env.environments.size).to eq(2)
    end
  end
  describe "#environment" do
    it "returns empty environment if it doesn't exist" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'full.yml'), :version => "1foo" )
      expect(env.environment).to eq({})
    end
    it "returns environment if it exists" do
      env = Pushwagner::Environment.new(:config_file => File.join(config_root, 'full.yml'), :version => "1foo", :environment => "staging")
      expect(env.environment).to eq({'hosts' => ["staging.uppercase.no"], 'user' => "www-data"})
    end
  end
  describe "#hosts" do
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
