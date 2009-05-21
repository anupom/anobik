require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('anobik', '0.0.1') do |p|
  p.description    = "Rack middleware Ruby micro-framework"
  p.url            = "http://github.com/anupom/anobik"
  p.author         = "Anupom Syam"
  p.email          = "anupom.syam@gmail.com"
  p.ignore_pattern = ["nbproject/*", "nbproject/private/*", "tmp/*"]
  p.development_dependencies = []
  p.runtime_dependencies = ['rack >= 0.9.1']
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each 