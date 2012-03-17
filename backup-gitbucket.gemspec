# -*- encoding: utf-8 -*-
# -*- mode: ruby -*-

Gem::Specification.new do |s|
  s.name        = "backup-gitbucket"
  s.version     = "0.1.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jens Braeuer"]
  s.email       = ["braeuer.jens@googlemail.com"]
  s.homepage    = "https://github.com/jbraeuer/backup-gitbucket"
  s.summary     = "Backup all your GitHub and BitBucket repositories"
  s.description = "Backup-gitbucket uses the API of GitHub and BitBucket to figure out all your repositories."
  s.required_rubygems_version = ">= 1.3.6"
  s.add_dependency "excon"
  s.add_development_dependency "rspec"
  s.files        = Dir.glob("{bin,lib}/**/*") + %w(config.yaml.sample LICENSE.txt Readme.markdown)
  s.executables  = ['backup-gitbucket']
  s.require_path = 'lib'
end
