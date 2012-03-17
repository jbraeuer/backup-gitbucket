module BackupGitBucket
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
            debug self, "Will list for #{@username} (bitbucket.org)"

            all_repos = { "self" => {} }

            repos = parse(validate(@conn.get(:path => "/1.0/user/repositories/")))
            repos = repos.select { |r| r["scm"] == "git" }
            repos.each do |r|
                next if @excludes.find { |exclude| exclude.match r["slug"] }
                all_repos["self"][r["slug"]] = "git@bitbucket.org:#{r["owner"]}/#{r["slug"]}.git"
            end

            all_repos
        end
    end
end
