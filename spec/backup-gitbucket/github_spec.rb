require 'spec_helper'

module BackupGitBucket
  describe GitHub do
    describe "#all" do

      let(:opts) do
        { :username => "testuser",
          :password => "testpassword",
          :excludes => [ ],
          :quiet => true }
      end
      let(:repos) do
        [ { "ssh_url" => "git@github.com:testuser/projectA.git",
            "name" => "projectA",
            "owner" => { "login" => "testuser" } },
          { "ssh_url" => "git@github.com:testuser/dotfiles.git",
            "name" => "dotfiles",
            "owner" => { "login" => "testuser" } } ]
      end
      let(:orgs) do
        [ { "login" => "ACME" } ]
      end
      let(:org_repos) do
        [ { "ssh_url" => "git@github.com:ACME/supersecret.git",
          "name" => "supersecret",
          "owner" => { "login" => "ACME" } } ]
      end
      before(:each) do
        Excon.mock = true
        Excon.stubs.clear
        Excon.stub({:method => :get, :host => 'api.github.com', :path => "/user/repos"},      {:body => repos.to_json , :status => 200})
        Excon.stub({:method => :get, :host => 'api.github.com', :path => "/user/orgs"},       {:body => orgs.to_json , :status => 200})
        Excon.stub({:method => :get, :host => 'api.github.com', :path => "/orgs/ACME/repos"}, {:body => org_repos.to_json , :status => 200})
      end

      it "should know about personal and organizational repos" do
        github = BackupGitBucket::GitHub.new opts

        github.all.should have_key("testuser")
        github.all.should have_key("ACME")
      end

      it "lists all my personal repositories" do
        github = BackupGitBucket::GitHub.new opts

        github.all["testuser"]["dotfiles"].should == "git@github.com:testuser/dotfiles.git"
        github.all["testuser"]["projectA"].should == "git@github.com:testuser/projectA.git"
      end

      it "lists all my organizational repositories" do
        github = BackupGitBucket::GitHub.new opts

        github.all["ACME"]["supersecret"].should == "git@github.com:ACME/supersecret.git"
      end

      it "excludes matching projects" do
        opts[:excludes] = [ "oject", "secret" ]

        github = BackupGitBucket::GitHub.new opts

        github.all["testuser"]["dotfiles"].should == "git@github.com:testuser/dotfiles.git"
        github.all["testuser"].should_not have_key("projectA")
        github.all.should_not have_key("ACME")
      end

      it "excludes matching organizations" do
        opts[:excludes] = [ "oject", "ACME" ]

        github = BackupGitBucket::GitHub.new opts
        github.all.should_not have_key("ACME")
        github.all.should have_key("testuser")
      end
    end
  end
end
