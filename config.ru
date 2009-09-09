require 'anobik/app'

ANOBIK_ROOT = "#{File.dirname(File.expand_path(__FILE__))}/" unless defined?(ANOBIK_ROOT)

PRODUCTION = false
DEBUGGER = true

app = Anobik::App::create DEBUGGER, PRODUCTION

run app