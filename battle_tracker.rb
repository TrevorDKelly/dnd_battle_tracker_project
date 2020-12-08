require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'sinatra/content_for'

require 'sysrandom/securerandom'

require_relative './lib/fight'

configure do
  set :erb, :escape_html => true
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
end

before do
  session[:fights] ||= []
end

helpers do
  def slugify(*names)
    names.map { |name| name.gsub(' ', '-') }.join('/')
  end

  def health_fill(character)
    percent = (character.hp / character.max_hp) * 100
    color = health_color(percent)
    "width:#{percent}%; background:#{color};"
  end
end

def health_color(percent)
    case percent
    when (90..100) then "#a6e647"
    when (70..89)  then "#d1e647"
    when (50..69)  then "#e6e147"
    when (30..49)  then "#e6be47"
    when (15..29)  then "#e66c47"
    else                "#c71c1c"
    end
end

def fight_name_taken?(name)
  session[:fights].any? { |fight| fight.name.downcase == name.downcase }
end

def fetch_fight(slug)
  name = slug.gsub('-', ' ')
  @fight = session[:fights].select { |fight| fight.name == name}.first
end

def valid_fight_name_error(name)
  if name.match(/[^a-zA-Z0-9 \(\)]/)
    "Fight name can only contain letters, numbers, parentheses, and spaces"
  elsif fight_name_taken?(name)
    "That name is already taken!"
  end
end

get "/" do
  @fights = session[:fights]
  erb :home
end

# New Fight
get "/new_fight" do
  erb :new_fight
end

post "/new_fight" do
  @name = params[:name]

  error = valid_fight_name_error(@name)

  if error
    session[:error] = error
    erb :new_fight
  else
    session[:fights] << Fight.new(@name)
    redirect "/#{slugify(@name)}"
  end
end

# Fight Page
get "/:fight_name" do
  fetch_fight(params[:fight_name])
  erb :fight
end

# Delete Fight
post "/:fight_name/delete" do
  fetch_fight(params[:fight_name])
  if @fight
    session[:success] = "#{@fight.name} was deleted"
    session[:fights].delete(@fight)
  else
    session[:error] = "That fight could not be found"
  end

  redirect "/"
end

# Duplicate Fight
post "/:fight_name/duplicate" do
  fetch_fight(params[:fight_name])
  if @fight
    session[:fights] << @fight.duplicate
    session[:success] = "#{@fight.name} was duplicated!"
  else
    session[:error] = "That fight could not be found"
  end

  redirect "/"
end

# New Character
get "/:fight_name/new_character" do
  fetch_fight(params[:fight_name])
  erb :new_character
end

post "/:fight_name/new_character" do
  fetch_fight(params[:fight_name])

  @name = params[:name]
  @hp = params[:hp]

  @fight.add_character(@name, @hp)

  redirect "/" + slugify(@fight.name)
end
