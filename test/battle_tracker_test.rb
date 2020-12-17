ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'minitest/reporters'
require 'rack/test'

require_relative '../battle_tracker'

MiniTest::Reporters.use!

class BattleTrackerTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def session
    last_request.env['rack.session']
  end

  def test_home
    get '/'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'No Fights Created Yet'
  end

  def test_session_has_fights_array
    get '/'

    assert_equal [], session[:fights]
  end

  def test_bad_page
    get '/not-real'

    assert_equal 302, last_response.status
    assert_equal 'That fight could not be found', session[:error]
  end

  def test_error_flash
    get '/', {}, { 'rack.session' => { error: 'an error' } }

    assert_includes last_response.body, "<div class='flash-box'>"
    assert_includes last_response.body, "<p>an error</p>"
  end

  def test_success_flash
    get '/', {}, { 'rack.session' => { success: 'a success' } }

    assert_includes last_response.body, "<div class='flash-box'>"
    assert_includes last_response.body, "<p>a success</p>"
  end

  def test_new_fight_page

  end
end
