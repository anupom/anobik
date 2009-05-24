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
#   URLS = {
#     "/" => "index",
#     "/index/(\\d+)" => "index",
#   }
# end
#
# * index.rb
# class Index
#   def get (id=nil)
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

    ERR_MESSAGES = {
      :missing_method => "Method %s::#%s not supported",
      :missing_class  => "Class %s not found in file %s.rb",
      :missing_file   => "File %s.rb missing in directory %s",
      :invalid_path   => "URL pattern unknown, Path %s not found",
      :missing_routes_file   => "Routes file %s.rb is not present in directory %s",
      :missing_routes_class   => "Class %s is missing in routes file %s.rb"
    }
    STATUSES = { :ok => 200, :bad_request => 404}
    ROUTES_FILENAME = 'routes'
    
    def initialize app, options
      @app = app
      @url = options[:url] || ''
      @url = '' if @url == '/'
      @production = options[:production]
      $LOAD_PATH << ANOBIK_ROOT
    end

    def call env
      req = Rack::Request.new(env)
      path = req.path_info
      method = req.request_method

      @headers = { 'Content-Type' => 'text/html' }

      #guard statements:
      unless path.index(@url) == 0
        return @app.call(env)
      end

      begin
        anobik_load ROUTES_FILENAME
      rescue Exception
        return anobik_error(:missing_routes_file, [ROUTES_FILENAME, ANOBIK_ROOT])
      end
      
      routes_classname = to_class_name ROUTES_FILENAME
      begin
        raise NameError unless Object.const_get(routes_classname).kind_of? Class
     rescue Exception
        return anobik_error(:missing_routes_class, [routes_classname, ANOBIK_ROOT+ROUTES_FILENAME])
      end
      
      begin
        urls = Object.const_get(routes_classname)::URLS
        raise unless urls.kind_of? Hash
      rescue Exception
        urls = {  "/" => "index" }
      end
      controller_filename = nil
      matches = nil
      urls.each do |regex, filename|
        matches = path.match(Regexp.new('^' << @url << regex << '/?$', true))
        unless  matches.nil?
          controller_filename = filename
          break
        end
      end

      if controller_filename.nil?
        return anobik_error(:invalid_path, [path])
      end

      begin
        anobik_load controller_filename
      rescue Exception
        return anobik_error(:missing_file, [controller_filename, ANOBIK_ROOT])
      end

      controller_classname = to_class_name controller_filename
      begin
        raise NameError unless Object.const_get(controller_classname).kind_of? Class
      rescue Exception
        return anobik_error(:missing_class, [controller_classname, ANOBIK_ROOT+controller_filename])
      end

      controller = Object.const_get(controller_classname).new
      unless controller.respond_to?(method)
        return anobik_error(:missing_method, [controller_classname, method])
      end

      body = eval 'controller.' << method <<
                        '(' << matches.captures.join(' , ') << ')'

      [STATUSES[:ok], @headers, body]
   end

    def to_class_name filename
      #shamelessly copied from Rails
      filename.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    end

    def anobik_error(err, array = [])
      #will be handled by RACK::ShowExceptions
      raise ERR_MESSAGES[err] % array unless @production
      #will be handled by RACK::ShowStatus
      return [STATUSES[:bad_request], @headers, '']
    end

    def anobik_root
      ANOBIK_ROOT
    end

    def anobik_load filename
      if (@production)
        require filename
      else
        classname = to_class_name(filename).to_sym
        Object.class_eval { remove_const classname } if Object.const_defined? classname
        Kernel.load filename + '.rb'
      end
    end
    
  end
end