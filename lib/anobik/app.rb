require 'rack'
require 'rack/anobik'
require 'anobik/utils'

module Anobik
  class App
    def self.create debugger, production
      Rack::Builder.new {
        use Rack::CommonLogger if debugger
        use Rack::ShowExceptions
        use Rack::ShowStatus
        use Rack::Static, :urls => ['/public']
        use Rack::Anobik, :url => '/',  :production => production

        #should never get through here if url is set to '/'
        run lambda { |env|
            [404, {'Content-Type' => 'text/plain'}, 'Not a Anobik Request :)']
         }
      }.to_app
    end
  end
end