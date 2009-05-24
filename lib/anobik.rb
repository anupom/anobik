require 'rack'
require 'rack/anobik'
require 'optparse'

class AnobikServer
  #
  # Runs the Anobik middleware app
  #
  def self.run
    #partially stolen from Rails
    options = {
      :Port => 3001,
      :Host => "0.0.0.0",
      :detach => false,
      :debugger => false,
      :production => false
    }

    ARGV.clone.options do |option|
      option.on("-p", "--port=port", Integer,
              "Runs Server on the specified port.", "Default: #{options[:Port]}") { |v| options[:Port] = v }
      option.on("-b", "--binding=ip", String,
              "Binds Server to the specified ip.", "Default: #{options[:Host]}") { |v| options[:Host] = v }
      option.on("-d", "--daemon", "Make server run as a Daemon.") { options[:detach] = true }
      option.on("-x", "--production", "Run the server in production mode.") { options[:production] = true }
      option.on("-u", "--debugger", "Enable rack server debugging.") { options[:debugger] = true }

      option.separator ""

      option.on("-h", "--help", "Show this help message.") { puts option.help; exit }
      option.parse!
    end

    unless server = Rack::Handler.get(ARGV.first) rescue nil
      begin
        server = Rack::Handler::Mongrel
      rescue LoadError => e
        server = Rack::Handler::WEBrick
      end
    end

    puts "=> Booting with #{server}"
    puts "=> Running in production mode" if options[:production]
    puts "=> Application starting on http://#{options[:Host]}:#{options[:Port]}#{options[:path]}"

    if options[:detach]
      puts "=> Running as deamon with pid: #{Process.pid}"
      Process.daemon
    else
       puts "=> Call with -d to detach"
    end

    app = Rack::Builder.new {
      use Rack::CommonLogger if options[:debugger]
      use Rack::ShowExceptions
      use Rack::ShowStatus
      use Rack::Static, :urls => ['/statics']
      use Rack::Anobik, :url => '/',  :production => options[:production]

      run lambda { |env|
          [404, {'Content-Type' => 'text/plain'}, 'Not a Anobik Request :)']
       }
    }.to_app

    trap(:INT) { exit }

    puts "=> Ctrl-C to shutdown server"

    begin
      server.run app, options.merge(:AccessLog => [])
    ensure
      puts "Exiting"
    end
  end
end