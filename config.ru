require 'anobik/app'

ANOBIK_ROOT = "#{File.dirname(File.expand_path(__FILE__))}/" unless defined?(ANOBIK_ROOT)

PRODUCTION = false
DEBUGGER = true

app = Anobik::App::create DEBUGGER, PRODUCTION

puts "=> Application starting on http://#{options[:Host]}:#{options[:Port]}#{options[:path]}"
puts "=> Ctrl-C to shutdown server"

run app