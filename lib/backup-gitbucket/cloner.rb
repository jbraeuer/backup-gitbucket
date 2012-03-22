require 'fileutils'

module BackupGitBucket
  class GitCloner
    include BackupGitBucket::Logging
    attr_reader :quiet

    def initialize(opts)
      @directory = opts[:directory]
      @dryrun = opts[:dryrun]
      @quiet = opts[:quiet]
    end

    def update_backup(reponame, repodir, ssh_url)
      info self, "Will update #{reponame} (#{ssh_url}) in #{repodir}"
      Dir.chdir(repodir) do
        unless @dryrun
          %x[git remote update]
          raise "Unable to update #{reponame}" unless $?.exitstatus == 0
        end
      end
    end

    def create_backup(reponame, dir, ssh_url)
      info self, "Will clone #{reponame} (#{ssh_url}) in #{dir}"
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
end
