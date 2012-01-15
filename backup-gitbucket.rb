#! /usr/bin/ruby

require 'rubygems'
require 'excon'
require 'pp'
require 'base64'
require 'json'
require 'fileutils'
require 'yaml'

module HTTPTools
    def basic_auth(username, password)
        credentials = Base64.encode64("#{username}:#{password}").strip
        return "Basic #{credentials}"
    end

    def validate(resp)
        raise "Did not get HTTP 200" unless resp.status == 200
        raise "Pagination not supported" if resp.headers.has_key? "X-Next"
        return resp
    end

    def parse(resp)
        return JSON.parse(resp.body)
    end
end

module Logging
    def debug(msg)
        puts msg
    end

    alias_method :info, :debug
    alias_method :warn, :debug
    alias_method :error, :debug
end

class GitCloner
    include Logging

    def initialize(opts)
        @directory = opts[:directory]
    end

    def update_backup(reponame, repodir, ssh_url)
        info "Will update #{reponame} (#{ssh_url}) in #{repodir}"
        Dir.chdir(repodir) do
            %x[git remote update]
            raise "Unable to update #{reponame}" unless $?.exitstatus == 0
        end
    end

    def create_backup(reponame, dir, ssh_url)
        info "Will clone #{reponame} (#{ssh_url}) in #{dir}"
        Dir.chdir(dir) do
            %x[git clone --mirror "#{ssh_url}"]
            raise "Unable to clone #{reponame}" unless $?.exitstatus == 0
        end
    end

    def backup
        repos = all()
        repos.each do |name, sub|
            dir = File.join(@directory, name)
            FileUtils.mkdir_p dir

            sub.each do |reponame, ssh_url|
                repodir = File.join(dir, "#{reponame}.git")
                if File.exist? repodir
                    update_backup(reponame, repodir, ssh_url)
                else
                    create_backup(reponame, dir, ssh_url)
                end
            end
        end
    end
end

class GitHub < GitCloner
    include HTTPTools

    def initialize(opts)
        super(opts)

        @username = opts[:username]
        @password = opts[:password]

        @conn = Excon.new("https://api.github.com",
                          :headers => {'Authorization' => basic_auth(@username, @password) })
    end

    # Build a hash <organization<name>> -> <git clone url>
    def all
        debug "Will list for #{@username} (github.com)"
        all_repos = {}
        all_orgs.each do |org, url|
            all_repos[org] = org_repos = {}

            repos = parse(validate(@conn.get(:path => url)))
            repos.each { |r| org_repos[r["name"]] = r["ssh_url"] }
        end
        all_repos
    end

    private

    # Build a hash <organization> -> <repository list url>
    def all_orgs
        all_orgs = parse(validate(@conn.get(:path => "/user/orgs")))
        all_orgs.inject({ "self" => "/user/repos" }) do |memo,o|
            memo[o["login"]] = "/orgs/#{o["login"]}/repos"
            memo
        end
    end
end

class BitBucket < GitCloner
    include HTTPTools

    def initialize(opts)
        super(opts)

        @username = opts[:username]
        @password = opts[:password]

        @conn = Excon.new("https://api.bitbucket.org",
                          :headers => {'Authorization' => basic_auth(@username, @password) })
    end

    def all
        debug "Will list for #{@username} (bitbucket.org)"

        all_repos = { "self" => {} }

        repos = parse(validate(@conn.get(:path => "/1.0/user/repositories/")))
        repos = repos.select { |r| r["scm"] == "git" }
        repos.each { |r| all_repos["self"][r["slug"]] = "git@bitbucket.org:#{@username}/#{r["slug"]}.git" }

        all_repos
    end
end

def main
    config = YAML::load File.open(ARGV[0])
    config.each do |item, opts|
        klass = Kernel.const_get(item)
        obj = klass.new(opts)
        obj.backup
    end
end

begin
    main
rescue => e
    warn e.message
    warn e.backtrace.join("\n")
end
