require 'anobik/consts'

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
# Anobik does not provide any database handling mechanism yet.
# You can ofcourse use any opensource database access layer with it - it's pretty flexible.
# Anobik is suitable for small micro-sites where you would love to use your
# favorite programming language but Rails is a bit heavy for that.
#
# Anobik acts as a Rack middleware app and that means you can use it with a
# number of webservers including Thin, LiteSpeed, Phusion Passangeretc.
# And the best part is, you can also use it with Rails, Sinatra or any other Rack based frameworks.
#
# Anobik is truely feather-weight. It has < 250 LOC!
# It does not have many features but it can get you started early.
# More docs coming soon, stay tuuneed!
#
# e.g:
#
# * configs/routes.rb
# class Routes
#   URLS = {
#     "/" => "index",
#     "/page/(\\d+)" => "page",
#   }
# end
#
# * resources/index.rb
# class Index < Anobik::Resource
#   def get
#     @hello = "Hello"
#     render 'index', {:world => 'world'}
#   end
# end
#
# * faces/index.erb
# <%= [@hello, @world].join(' ') %>
#
# * command
# $ ruby -rubygems server
# OR
# $ rackup config.ru
#
# * url
# GET /index/1
# 
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
      method = req.request_method.downcase

      @headers = { 'Content-Type' => 'text/html' }

      #guard statements:
      unless path.index(@url) == 0
        return @app.call(env)
      end

      begin
        anobik_load_config ::Anobik::ROUTES_FILE
      rescue LoadError => msg
        return system_error msg
      end
      
      routes_classname = to_class_name ::Anobik::ROUTES_FILE
      begin
        raise NameError unless Object.const_get(routes_classname).kind_of? Class
      rescue Exception
        return anobik_error(:missing_routes_class,
          [routes_classname, ANOBIK_ROOT + ::Anobik::CONFIG_DIR +
                                                ::Anobik::ROUTES_FILE])
      end
      
      begin
        urls = Object.const_get(routes_classname)::URLS
        raise unless urls.kind_of? Hash
      rescue Exception
        urls = {  "/" => "index" }
      end
      resource_filename = nil
      matches = nil
      urls.each do |regex, filename|
        matches = path.match(Regexp.new('^' << @url << regex << '/?$', true))
        unless  matches.nil?
          resource_filename = filename
          break
        end
      end

      if resource_filename.nil?
        return anobik_error(:invalid_path, [path])
      end

      begin
        anobik_load_resource resource_filename
      rescue LoadError => msg
        return system_error msg
      end

      resource_classname = to_class_name resource_filename
      begin
        raise NameError unless Object.const_get(resource_classname).kind_of? Class
      rescue Exception
        return anobik_error(:missing_class, [resource_classname, ANOBIK_ROOT +
                                ::Anobik::RESOURCE_DIR + resource_filename])
      end

      resource = Object.const_get(resource_classname).new(){env}
      unless resource.respond_to?(method)
        return anobik_error(:missing_method, [resource_classname, method])
      end

      body = eval 'resource.' << method <<
                        '(' << matches.captures.join(' , ') << ')'

      [STATUSES[:ok], @headers, body]
   end

    def to_class_name filename
      #shamelessly copied from Rails
      filename.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    end

    def anobik_error(err, array = [])
      raise ERR_MESSAGES[err] % array unless @production
      return bad_request
    end

    def system_error msg
      raise msg unless @production
      return bad_request
    end

    def bad_request
      [STATUSES[:bad_request], @headers, '']
    end

    def anobik_load_config filename
      anobik_load ::Anobik::CONFIG_DIR, filename
    end

    def anobik_load_resource filename
      anobik_load ::Anobik::RESOURCE_DIR, filename
    end

    def anobik_load dirname, filename
      if (@production)
        require dirname + filename
      else
        classname = to_class_name(filename).to_sym
        Object.class_eval { remove_const classname } if Object.const_defined? classname
        Kernel.load dirname + filename + '.rb'
      end
    end

    def anobik_root
      ANOBIK_ROOT
    end
    
  end
end