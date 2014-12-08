require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'pushwagner/environment'

describe Pushwagner::Hooks do
  #let(:cfg) {YAML::load_file(File.join(config_root, 'hooks.yml'))}

  let(:env) { Pushwagner::Environment.new(config_file: File.join(config_root, 'hooks.yml')) }

  describe "#initialize" do
    it "raises error if invalid environment" do
      expect { Pushwagner::Hooks.new(nil) }.to raise_exception
    end

    it "returns an empty config with an empty environment" do
      sut = Pushwagner::Hooks.new(Pushwagner::Environment.new(config_file: File.join(config_root, 'empty.yml')))
      expect(sut.local.before).to eq([])
      expect(sut.local.after).to eq([])
      expect(sut.remote.before).to eq([])
      expect(sut.remote.after).to eq([])
    end

    it "returns a full working config" do
      sut = Pushwagner::Hooks.new(env)
      expect(sut.remote.before).to eq(['ls', 'echo "foo"'])
      expect(sut.remote.after).to eq([])
      expect(sut.local.before).to eq(['echo "one"'])
      expect(sut.local.after).to eq(['echo "two"', 'echo "three"'])
    end
  end
  describe "#run" do
    it "requires an argument" do
      sut = Pushwagner::Hooks.new(env)
      expect { sut.run() }.to raise_exception
    end

    it "accepts run :after target" do
      sut = Pushwagner::Hooks.new(env)

      sut.stub_chain("local.run").with(:after).once
      sut.stub_chain("remote.run").with(:after).once

      sut.run(:after)
    end

    it "accepts run :before target" do
      sut = Pushwagner::Hooks.new(env)

      sut.stub_chain("local.run").with(:before).once
      sut.stub_chain("remote.run").with(:before).once

      sut.run(:before)
    end
  end

end

describe Pushwagner::Hooks::Local do
  let(:env) { Pushwagner::Environment.new(config_file: File.join(config_root, 'hooks.yml')) }

  describe "#initialize" do
    it "returns an empty config without a config" do
      sut = Pushwagner::Hooks::Local.new(env, env.hooks['local'])
      expect(sut.before).to eq(['echo "one"'])
      expect(sut.after).to eq(['echo "two"', 'echo "three"'])
    end
  end

  describe "#run" do
    it "requires an argument" do
      sut = Pushwagner::Hooks::Local.new(env, env.hooks['local'])

      expect { sut.run() }.to raise_exception
    end
    it "supports :before hooks" do
      sut = Pushwagner::Hooks::Local.new(env, env.hooks['local'])

      Pushwagner.stub(:info)
      Pushwagner.stub(:begin_info)
      Pushwagner.stub(:ok)

      sut.should_receive(:system).with('echo "one"').once
      sut.run(:before)
    end
    it "supports :after hooks" do
      sut = Pushwagner::Hooks::Local.new(env, env.hooks['local'])

      Pushwagner.stub(:info)
      Pushwagner.stub(:begin_info)
      Pushwagner.stub(:ok)

      sut.should_receive(:system).with('echo "two"').once
      sut.should_receive(:system).with('echo "three"').once
      sut.run(:after)
    end
  end

end

describe Pushwagner::Hooks::Remote do
  let(:env) { Pushwagner::Environment.new(config_file: File.join(config_root, 'hooks.yml')) }

  describe "#initialize" do
    it "returns an empty config without a config" do
      sut = Pushwagner::Hooks::Remote.new(env, env.hooks['remote'])
      expect(sut.before).to eq(['ls', 'echo "foo"'])
      expect(sut.after).to eq([])
    end
  end

  describe "#run" do
    it "requires an argument" do
      sut = Pushwagner::Hooks::Remote.new(env, env.hooks['remote'])

      expect { sut.run() }.to raise_exception
    end

    it "supports :before hooks" do
      sut = Pushwagner::Hooks::Remote.new(env, env.hooks['remote'])

      Pushwagner.stub(:info)
      Pushwagner.stub(:begin_info)
      Pushwagner.stub(:ok)

      # Mock Net::SSH inner interaction smoke test
      ssh = mock
      ssh.should_receive(:open_channel).exactly(4).times
      ssh.should_receive(:loop).exactly(4).times
      Net::SSH.should_receive(:start).and_yield(ssh).exactly(4).times

      sut.run(:before)
    end

    it "supports :after hooks" do
      sut = Pushwagner::Hooks::Remote.new(env, env.hooks['remote'])

      # Mock Net::SSH inner interaction smoke
      ssh = mock
      ssh.should_receive(:open_channel).never
      Net::SSH.should_receive(:start).and_yield(ssh).never

      sut.run(:after)
    end
  end

end
