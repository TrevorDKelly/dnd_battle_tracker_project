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

  def session_with_fight
    { 'rack.session' => { fights: [create_fight] } }
  end

  def create_fight(characters = 0)
    fight = Fight.new('fight')
    characters.times do |n|
      fight << Character.new({ name: "npc_#{n}", hp: 10, type: 'npc' })
    end

    fight
  end

  # Tests

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

  def test_home_page_with_fight
    get '/', {}, session_with_fight

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<div class='list-box fight'>"
  end

  def test_new_fight_page
    get '/new_fight'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<h2>Prepping a New Fight</h2>'
  end

  def test_new_fight_post
    post '/new_fight', { name: 'fight name' }

    assert_equal 302, last_response.status
    assert_equal 1, session[:fights].size
  end

  def test_new_fight_cant_have_empty_name
    post '/new_fight', { name: '' }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Name can't be empty!"
  end

  def test_new_fight_cant_be_all_spaces
    post '/new_fight', { name: '   ' }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Name can't be empty!"
  end

  def test_new_fight_cant_have_special_characters
    post '/new_fight', { name: 'name!' }

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Name can only contain letters, '
  end

  def test_new_fight_can_have_parentheses_and_numbers
    post '/new_fight', { name: '(1)' }

    assert_equal 302, last_response.status
    assert_equal 1, session[:fights].size
  end

  def test_new_fight_strips_extra_spaces_from_ends
    post '/new_fight', { name: '    name    ' }

    assert_equal 302, last_response.status
    assert_equal 'name', session[:fights][0].name
  end

  def test_new_fight_wont_allow_duplicate_name
    post '/new_fight', { name: 'fight' }, session_with_fight

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'That name is already taken!'
  end

  def test_fight_page_empty
    get '/fight', {}, session_with_fight

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'No Characters Created Yet'
  end
end
