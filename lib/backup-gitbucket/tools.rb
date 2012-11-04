require 'base64'
require 'json'

module BackupGitBucket
  module HTTPTools
    def basic_auth(username, password)
      credentials = Base64.encode64("#{username}:#{password}").strip
      return "Basic #{credentials}"
    end

    def validate(resp)
      raise "Did not get HTTP 200 (but a #{resp.status})" unless resp.status == 200
      raise "Pagination not supported" if resp.headers.has_key? "X-Next"
      return resp
    end

    def parse(resp)
      return JSON.parse(resp.body)
    end
  end

  module Logging
    def debug(obj, msg)
      puts msg unless obj.quiet
    end

    alias_method :info, :debug
    alias_method :warn, :debug
    alias_method :error, :debug
  end
end
