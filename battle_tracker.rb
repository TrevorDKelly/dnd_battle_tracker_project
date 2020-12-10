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

  def health_fill(object)
    percent = if object.kind_of? Character
                (object.hp.to_f / object.max_hp) * 100
              elsif object.kind_of? Fight
                object.npc_health_percentage
              end

    color = health_color(percent)
    "width:#{percent}%; background:#{color};"
  end

  def each_available_stat(character)
    stats = [:initiative, :char_class, :race, :size]
    type = character.is_npc? ? 'NPC' : 'Player'

    yield('Type', type)

    stats.each do |stat|
      name = stat.to_s.gsub('_', ' ').capitalize
      value = character.public_send(stat)

      yield(name, value) if value
    end
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

  fight_not_found unless @fight
end

def fetch_character(name)
  @character = @fight.fetch_character(name)
end

def valid_fight_name_error(name)
  if name.match(/[^a-zA-Z0-9 \(\)]/)
    "Fight name can only contain letters, numbers, parentheses, and spaces"
  elsif fight_name_taken?(name)
    "That name is already taken!"
  elsif name.empty?
    "Name can't be empty!"
  end
end

def fight_not_found
  session[:error] = "That fight could not be found"
  redirect "/"
end

# Paths
get "/" do
  @fights = session[:fights]
  erb :home
end

# New Fight
get "/new_fight" do
  erb :new_fight
end

post "/new_fight" do
  @name = params[:name].strip

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

  session[:success] = "#{@fight.name} was deleted"
  session[:fights].delete(@fight)

  redirect "/"
end

# Duplicate Fight
post "/:fight_name/duplicate" do
  fetch_fight(params[:fight_name])

  session[:fights] << @fight.duplicate(session[:fights])
  session[:success] = "#{@fight.name} was duplicated!"

  redirect "/"
end

# edit fight
get "/:fight_name/edit" do
  fetch_fight(params[:fight_name])
  @name = @fight.name

  erb :edit_fight
end

post "/:fight_name/edit" do
  fetch_fight(params[:fight_name])
  @name = params[:name].strip

  redirect "/#{slugify(@name)}" if @name == @fight.name

  error = valid_fight_name_error(@name)

  if error
    session[:error] = error
    erb :edit_fight
  else
    @fight.name = @name
    session[:success] = "Fight Name Changed!"
    @fight.last_event = "Fight name Changed"
    redirect "/#{slugify(@name)}"
  end
end

# Restart Fight
post "/:fight_name/restart" do
  fetch_fight(params[:fight_name])

  @fight.characters.each(&:full_heal)
  @fight.status = 'Prepping'

  @fight.last_event = "Fight restarted"
  redirect "/#{slugify(@fight.name)}"
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

# Take and Heal Damage

post "/:fight_name/:character_name/take_damage/*" do
  fetch_fight(params[:fight_name])
  fetch_character(params[:character_name])

  damage = params[:amount]

  if params['splat'].first == 'full'
    @character.full_damage
  else
    @character.take_damage(damage)
    @fight.last_event = "#{@character.name} took #{damage} points of damage"
  end

  redirect "/#{slugify(@fight.name)}"
end

post "/:fight_name/:character_name/heal_damage/*" do
  fetch_fight(params[:fight_name])
  fetch_character(params[:character_name])

  heal = params[:amount]

  if params['splat'].first == 'full'
    @character.full_heal
  else
    @character.heal(heal)
    @fight.last_event = "#{@character.name} healed #{heal} points"
  end

  redirect "/#{slugify(@fight.name)}"
end

# Delete Character
post "/:fight_name/:character_name/delete" do
  fetch_fight(params[:fight_name])
  fetch_character(params[:character_name])

  @fight.last_event = "#{@character.name} removed"
  @fight.characters.delete(@character)

  redirect "/#{slugify(@fight.name)}"
end

#Duplicate Character
post "/:fight_name/:character_name/duplicate" do
  fetch_fight(params[:fight_name])
  fetch_character(params[:character_name])

  @fight.last_event = "#{@character.name} duplicated"
  @fight << @character

  redirect "/#{slugify(@fight.name)}"
end
