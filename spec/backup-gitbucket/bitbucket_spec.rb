require 'spec_helper'

module BackupGitBucket
  describe BitBucket do
    describe "#all" do

      let(:opts) do
        { :username => "testuser",
          :password => "testpassword",
          :excludes => [ ],
          :quiet => true }
      end
      let(:repositories) do
        repositories = [ { "owner" => "testuser",
                           "scm" => "git",
                           "slug" => "projectA",
                           "is_private" => false,
                           "name" => "Project A" },
                         { "owner" => "testuser",
                           "scm" => "git",
                           "slug" => "dotfiles",
                           "is_private" => true,
                           "name" => "dotfiles" } ]
      end
      before(:each) do
        Excon.mock = true
        Excon.stubs.clear
        Excon.stub({:method => :get, :host => 'api.bitbucket.org', :path => "/1.0/user/repositories/"}, {:body => repositories.to_json , :status => 200})
      end

      it "lists all my personal repositories" do
        bitbucket = BackupGitBucket::BitBucket.new opts

        bitbucket.all["testuser"]["dotfiles"].should == "git@bitbucket.org:testuser/dotfiles.git"
        bitbucket.all["testuser"]["projectA"].should == "git@bitbucket.org:testuser/projectA.git"
      end

      it "excludes matching projects" do
        opts[:excludes] = [ "oject" ]

        bitbucket = BackupGitBucket::BitBucket.new opts

        bitbucket.all["testuser"]["dotfiles"].should == "git@bitbucket.org:testuser/dotfiles.git"
        bitbucket.all["testuser"].should_not have_key("projectA")
      end
    end
  end
end
