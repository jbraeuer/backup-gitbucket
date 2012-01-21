module BackupGitBucket
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
            debug self, "Will list for #{@username} (github.com)"
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
end
