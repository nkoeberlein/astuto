require 'rake'
require 'net/http'
require 'uri'

task :healthcheck, [:port] do |_t, args|
  port = args[:port] || 3000

  # Make the HTTP request to the health endpoint
  uri = URI.parse("http://localhost:#{port}/health")
  response = Net::HTTP.get_response(uri)
  
  exit_code = response.is_a?(Net::HTTPSuccess) ? 0 : 1

rescue
  exit_code = 1

ensure
  puts "Healthcheck returned: #{exit_code}"
  exit(exit_code)
end
