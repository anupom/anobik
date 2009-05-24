require 'test/spec'

require 'rack'
require 'rack/mock'
require 'rack/anobik'

ANOBIK_ROOT = "#{File.dirname(File.expand_path(__FILE__))}/" unless defined?(ANOBIK_ROOT)

describe "Rack::Anobik" do

  class EqualResponse < Test::Spec::CustomShould
    def assumptions(response)
      response.status.should.equal(object[:status])
      response.body.should.match(object[:body])
    end
  end

  def equal_response(response)
    EqualResponse.new(response)
  end

  class EqualNotFound < Test::Spec::CustomShould
    def assumptions(response)
      response.status.should.equal(404)
      response.body.should.match('Not Found')
    end
  end

  def equal_not_found()
    EqualNotFound.new(nil)
  end

  setup do
    remove_routes_file
    remove_file 'index'
  end

  it "should return default when non-anobik URL with production" do
    response = anobik_app_production( '/other/').get('/')
    response.should equal_response({:status => 200, :body => 'Not a Anobik Request'})
  end

  it "should return default when non-anobik url requested with dev" do
    response = anobik_app_dev('/other/').get('/')
    response.should equal_response({:status => 200, :body => 'Not a Anobik Request'})
  end

  it "should have the same ANOBIK_ROOT" do
      ANOBIK_ROOT.should.equal( Rack::Anobik.new(nil, options('/', false)).anobik_root)
  end

  it "should return 404 when routes.rb is not present with production" do
    remove_routes_file
    response = anobik_app_production.get('/')
    response.should equal_not_found
  end

  it "should return 500 when routes.rb is not present with dev" do
    remove_routes_file
    response = anobik_app_dev.get('/')
    response.should equal_response({:status => 500, :body => 'routes.rb ' << 'is not present in directory'})
  end

  it "should return 404 when Routes class is not defined with production" do
    create_routes_file ''
    response = anobik_app_production.get('/')
    response.should equal_not_found
    remove_routes_file
  end

  it "should return 500 when Routes class is not defined with dev" do
    create_routes_file ''
    response = anobik_app_dev.get('/')
    response.should equal_response({:status => 500, :body => 'Class Routes ' << 'is missing in routes file'})
    remove_routes_file
  end

  it "should return 404 when no URL pattern matches with production" do
    create_routes_file "class Routes\nend"
    response = anobik_app_production.get('/unknown/pattern')
    response.should equal_not_found
    remove_routes_file
  end

  it "should return 500 when no URL pattern matches with dev" do
    create_routes_file "class Routes\nend"
    response =anobik_app_dev.get('/unknown/pattern')
    response.should equal_response({:status => 500, :body => 'URL pattern ' << 'unknown'})
    remove_routes_file
  end

  it "should return 404 when filename does not exist with production" do
    remove_file 'index'
    create_routes_file "class Routes\nend"
    response = anobik_app_production.get('/')
    response.should equal_not_found
    remove_routes_file
  end

  it "should return 500 when filename does not exist with dev" do
    remove_file 'index'
    create_routes_file "class Routes\nend"
    response = anobik_app_dev.get('/')
    response.should equal_response({:status => 500, :body => 'missing ' << 'in directory'})
    remove_routes_file
  end

  it "should return 404 when filename exists but class missing with production" do
    create_routes_file "class Routes\nend"
    create_file 'index', ''
    response = anobik_app_production.get('/')
    response.should equal_not_found
    remove_routes_file
    remove_file 'index'
  end

  it "should return 500 when filename exists but class missing with dev" do
    create_routes_file "class Routes\nend"
    create_file 'index', ''
    response = anobik_app_dev.get('/')
    response.should equal_response({:status => 500, :body => 'Class Index ' << 'not found in file'})
    remove_routes_file
    remove_file 'index'
  end

  it "should return 404 when class exists but method missing with production" do
    create_routes_file "class Routes\nend"
    create_file 'index', "class Index\nend"
    response = anobik_app_production.get('/')
    response.should equal_not_found
    remove_routes_file
    remove_file 'index'
  end

  it "should return 500 when class exists but method missing with dev" do
    create_routes_file "class Routes\nend"
    create_file 'index', "class Index\nend"
    response = anobik_app_dev.get('/')
    response.should equal_response({:status => 500, :body => 'Method Index::#GET ' << 'not supported'})
    remove_routes_file
    remove_file 'index'
  end

  it "should return 200 for GET when everything's ok" do
    create_routes_file routes_file
    create_file 'index', index_file
    response = anobik_app_dev.get('/')
    response.should equal_response({:status => 200, :body => 'GET_' << 'SUCCESS'})
    remove_routes_file
    remove_file 'index'
  end

  it "should return 200 when regex is valid" do
    create_routes_file routes_file
    create_file 'index', index_file
    response = anobik_app_dev.get('/index/98')
    response.should equal_response({:status => 200, :body => 'GET_' << 'SUCCESS98'})
    remove_routes_file
    remove_file 'index'
  end

  xit "should return 200 when root URL is called and index is  present" do
    create_routes_file routes_file
    create_file 'index', index_file
    response = anobik_app_dev.get('/')
    response.should equal_response({:status => 200, :body => 'GET_' << 'SUCCESS'})
    remove_routes_file
    remove_file 'index'
  end
  
  it "should handle POST data" do
    create_routes_file routes_file
    create_file 'index', index_file
    response = anobik_app_dev.post('/')
    response.should equal_response({:status => 200, :body => 'POST_SUC' << 'CESS'})
    remove_routes_file
    remove_file 'index'
  end
  
  xit "should handle DELETE requests" do
  end
  
  xit "should handle PUT request" do
  end

  xit "should handle pseudo-DELETE requests" do
  end

  xit "should handle pseudo-PUT request" do
  end

  def anobik_app options
    Rack::Builder.new {
      use Rack::ShowExceptions
      use Rack::ShowStatus
      use Rack::Static, :urls => ['/statics']
      use Rack::Anobik, :url => options[:url],  :production => options[:production]
      run lambda { |env|
        [200, { 'Content-Type' => 'text/plain' }, 'Not a Anobik Request :)']
      }
    }.to_app
  end

  def anobik_app_production anobik_url=nil
    anobik_url = '/' if anobik_url.nil?
    Rack::MockRequest.new(anobik_app options(anobik_url, true))
  end

  def anobik_app_dev anobik_url=nil
    anobik_url = '/' if anobik_url.nil?
    Rack::MockRequest.new(anobik_app options(anobik_url, false))
  end

  def options url, production
    { :url => url,  :production =>production }
  end

  def create_routes_file str
    create_file 'routes', str
  end

  def remove_routes_file
    remove_file 'routes'
  end

  def create_file filename, str
    ::File.open(ANOBIK_ROOT + filename + '.rb', 'w') {|f| f.write(str) }
  end

  def remove_file filename
    ::File.delete(ANOBIK_ROOT + filename + '.rb')  if ::File.exist?(ANOBIK_ROOT + filename + '.rb')
  end

  def index_file
    return "class Index\n" <<
              "def GET(id=nil)\n" <<
                "'GET_SUCCESS'<<id.to_s\n" <<
              "end\n" <<
              "def POST()\n" <<
                "'POST_SUCCESS'\n" <<
              "end\n" <<
            "end"
  end
  
  def routes_file
    "class Routes\nURLS = {\n'/' => 'index',\n'/index/(\\d+)' => 'index'\n}\nend"
  end
end