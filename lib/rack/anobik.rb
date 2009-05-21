module Rack
#
# Anobik is a Rack based microframework that provides an easy way to map URL patterns to classes.
# URL patterns can be literal strings or regular expressions.
# when URLs are processed:
# 	* the beginning and end are anchored (^ $)
# 	* an optional end slash is added (/?)
# 	* the i option is added for case-insensitive searches
# 	* respective class method is called depending on the request method (GET/POST etc.)
#
# It does not provide any view templating or database handling mechanism.
# you can ofcourse use any opensource view templating engine or database access layer with it.
# Anobik is very similar to web.py, but it is not a direct clone of web.py.
# It is ofcourse highly inspired by web.py and other similar lightweight microframeworks.
#
# Anobik acts as a Rack middleware app and that means you can use it with a
# number of webservers including Thin, LiteSpeed, Phusion Passangeretc.
# And BTW, you can also use it with Rails, Sinatra or any other Rack based frameworks.
#
# e.g:
#
# * routes.rb
# class Routes
#   BASE = ''
#   URLS = {
#     "/" => "index",
#     "/index/(\\d+)" => "index",
#   }
# end
#
# * index.rb
# class Index
#   def self.GET (id=nil)
#     "Hello world from web.rb! #{id}"
#   end
# end
#
# * url
# GET /index/1
#
# MIT-License - Anupom Syam
#
  class Anobik

    def initialize app, options
      @app = app
      @urls = options[:urls] || ['/']
      @production = options[:production]
      @err_messages = {
        :missing_method => "Method %s::#%s not supported",
        :missing_class  => "Class %s not found in file %s.rb",
        :missing_file   => "File %s.rb missing in directory %s",
        :invalid_path   => "URL pattern unknown, Path %s not found"
      }
      @statuses = { :ok => 200, :bad_request => 404}
      @routes_filename = 'routes'
    end

    def call env
      req = Rack::Request.new(env)
      path = req.path_info
      status = @statuses[:bad_request]
      body = ''
      err = false

      if @urls.any? { |url| path.index(url) == 0 }
          if ::File.exist?( ANOBIK_ROOT + @routes_filename + ".rb")
            require 'routes'
            base_path = ANOBIK_ROOT + Routes::BASE
            found = false
            Routes::URLS.each do |regex, filename|
              if matches = path.match(Regexp.new('^' << regex << '/?$', true))
                found = true
                if ::File.exist?(base_path + filename + ".rb")
                  require filename
                  #shamelessly copied from Rails
                  classname = filename.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
                  begin klass = Object.const_get(classname) rescue nil end
                  if klass.kind_of? Class
                    if klass.respond_to?(req.request_method)
                      #@body = klass.send req.request_method.to_sym, matches
                      body = eval 'klass' << '::' << req.request_method <<
                                   '(' << matches.captures.join(' , ') << ')'
                      status = @statuses[:ok]
                    else
                      err = @err_messages[:missing_method] % [classname, req.request_method]
                    end
                  else
                    err = @err_messages[:missing_class] % [classname, filename]
                  end
                else
                  err = @err_messages[:missing_file] % [filename, @base_path]
                end
                break
              end
            end
            unless found
             err = @err_messages[:invalid_path] % path
            end
          else
             err = @err_messages[:missing_file] % [@routes_filename, ANOBIK_ROOT]
          end
          
          raise err if err && !@production

          [status, {'Content-Type' => 'text/html'}, body]
      else
        @app.call(env)
      end
    end
  end
end