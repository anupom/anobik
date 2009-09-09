require 'anobik/consts'

#TODO make @request/@response $request/$response?

module Anobik
  class Resource
    def initialize
      @anobik_env = yield
      @request = Rack::Request.new(@anobik_env)
      @response = Rack::Request.new(@anobik_env)
    end
    
    def render facename, local_assigns = {}
      local_assigns.each do |key,value|
       eval "@#{key} = #{value.inspect}"
      end
      ERB.new(File.read(ANOBIK_ROOT + ::Anobik::FACES_DIR + facename + '.erb')).result(binding)
    end
  end
end