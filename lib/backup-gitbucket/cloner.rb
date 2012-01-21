require 'excon'
require 'pp'
require 'fileutils'

class GitCloner
    include BackupGitBucket::Logging

    def initialize(opts)
        @directory = opts[:directory]
        @dryrun = opts[:dryrun]
    end

    def update_backup(reponame, repodir, ssh_url)
        info "Will update #{reponame} (#{ssh_url}) in #{repodir}"
        Dir.chdir(repodir) do
            unless @dryrun
                %x[git remote update]
                raise "Unable to update #{reponame}" unless $?.exitstatus == 0
            end
        end
    end

    def create_backup(reponame, dir, ssh_url)
        info "Will clone #{reponame} (#{ssh_url}) in #{dir}"
        Dir.chdir(dir) do
            unless @dryrun
                %x[git clone --mirror "#{ssh_url}"]
                raise "Unable to clone #{reponame}" unless $?.exitstatus == 0
            end
        end
    end

    # Calculates all known git-repository by querying some API.
    #
    # Returns: Hash<String, Hash<String, String>>
    #
    # Example:
    # { 'self' : { 'projectA': 'git@github.com/user/projectA',
    #              'projectB': 'git@github.com/user/projectB' },
    #   'org1' : { 'orgprojA': 'git@github.com/org1/orgprojA',
    #              'orgprojB': 'git@github.com/org1/orgprojB' } }
    def all
        raise "Implement me in a subclass"
    end

    def backup
        all.each do |division, repos|
            division_dir = File.join(@directory, division)
            FileUtils.mkdir_p division_dir

            repos.each do |name, ssh_url|
                repodir = File.join(division_dir, "#{name}.git")
                if File.exist? repodir
                    update_backup(name, repodir, ssh_url)
                else
                    create_backup(name, division_dir, ssh_url)
                end
            end
        end
    end
end

class GitHub < GitCloner
    include BackupGitBucket::HTTPTools

    def initialize(opts)
        super(opts)

        @username = opts[:username]
        @password = opts[:password]

        @excludes = opts[:excludes].map { |r| Regexp.new(r) } if opts.has_key? :excludes
        @excludes ||= []

        @conn = Excon.new("https://api.github.com",
                          :headers => {'Authorization' => basic_auth(@username, @password) })
    end

    # Build a hash <organization<name>> -> <git clone url>
    def all
        debug "Will list for #{@username} (github.com)"
        all_repos = {}
        all_orgs.each do |org, url|
            next if @excludes.find { |exclude| exclude.match org }
            all_repos[org] = org_repos = {}

            repos = parse(validate(@conn.get(:path => url)))
            repos.each do |r|
                next if @excludes.find { |exclude| exclude.match r["name"] }
                org_repos[r["name"]] = r["ssh_url"]
            end
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
    include BackupGitBucket::HTTPTools

    def initialize(opts)
        super(opts)

        @username = opts[:username]
        @password = opts[:password]

        @excludes = opts[:excludes].map { |r| Regexp.new(r) } if opts.has_key? :excludes
        @excludes ||= []

        @conn = Excon.new("https://api.bitbucket.org",
                          :headers => {'Authorization' => basic_auth(@username, @password) })
    end

    def all
        debug "Will list for #{@username} (bitbucket.org)"

        all_repos = { "self" => {} }

        repos = parse(validate(@conn.get(:path => "/1.0/user/repositories/")))
        repos = repos.select { |r| r["scm"] == "git" }
        repos.each do |r|
            next if @excludes.find { |exclude| exclude.match r["slug"] }
            all_repos["self"][r["slug"]] = "git@bitbucket.org:#{@username}/#{r["slug"]}.git"
        end

        all_repos
    end
end
