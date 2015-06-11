require 'uri'

module Puppet::Parser::Functions
  newfunction(:parse_server_id, :type => :rvalue) do |args|
    uri = URI.parse(args[0])
    uri.host.gsub(/\./, '_')
  end
end
