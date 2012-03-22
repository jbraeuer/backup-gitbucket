require 'yaml'

module BackupGitBucket
  class CLI
    def initialize(args=ARGV)
      @args = args
      @config = YAML::load File.open(@args[0])
      @global = @config.delete(:global)
    end
    def main(args=ARGV)
      @config.each do |item, opts|
        klass = Kernel.const_get("BackupGitBucket").const_get(item)
        obj = klass.new(opts.merge(@global))
        obj.backup
      end
    end
  end
end
