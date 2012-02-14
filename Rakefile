# -*- encoding: utf-8; mode: ruby -*-

require 'rspec/core/rake_task'

task :default => :spec

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = [ '--format documentation', '--color' ]
end
