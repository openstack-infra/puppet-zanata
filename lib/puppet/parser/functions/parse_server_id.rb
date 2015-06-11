require 'uri'

module Puppet::Parser::Functions
  newfunction(:parse_server_id, :type => :rvalue) do |args|
    uri = URI.parse(args[0])
    unless uri.host.nil?
      uri.host.gsub(/\./, '_')
    end
  end
end
