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

  def each_basic_stat(character)
    stats = [:type, :initiative_bonus, :race, :size]


    stats.each do |stat|
      name = stat.to_s.gsub('_', ' ').capitalize
      value = character.public_send(stat)

      yield(name, value) unless value.empty?
    end

    yield('Class', character.char_class) unless character.char_class.empty?
    yield('Last Event', character.last_event)
  end

  def each_ability_score(character)
    character.ability_scores.each do |name, value|
      unless value.empty?
        bonus = ((value.to_i - 10) / 2).floor
        bonus = bonus.negative? ? bonus.to_i : "+#{bonus}"
        name = name[0..2].upcase
        yield(name, value, bonus)
      end
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

def fetch_character(slug)
  name = slug.gsub('-', ' ')
  @character = @fight.fetch_character(name)
end

def valid_name_error(name, collection)
  if name.match(/[^a-zA-Z0-9 \(\)]/)
    "Name can only contain letters, numbers, parentheses, and spaces"
  elsif name.empty?
    "Name can't be empty!"
  elsif collection.include?(name)
    "That name is already taken!"
  end
end

def fight_not_found
  session[:error] = "That fight could not be found"
  redirect "/"
end

def set_edit_character_prefills(character)
  params[:name] = character.name
  params[:hp] = character.max_hp
  params[:ac] = character.ac
  params[:initative_bonus] = character.initiative_bonus
  params[:char_class] = character.char_class
  params[:race] = character.race
  @ability_scores = character.ability_scores
  params[:notes] = character.notes
  params[:type] = character.type
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

  existing_names = session[:fights].map(&:name)
  error = valid_name_error(@name, existing_names)

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
  @all_conditions = Character.conditions

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

  existing_names = session[:fights].map(&:name)
  existing_names.delete(@fight.name)
  error = valid_name_error(@name, existing_names)

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

  @fight.restart
  redirect "/#{slugify(@fight.name)}"
end

# New Character
get "/:fight_name/new_character" do
  fetch_fight(params[:fight_name])

  @title = "Creating New Character in #{@fight.name}"
  @submit_button = "Submit New Character"
  @post_location = "/#{slugify(@fight.name)}/new_character"
  erb :character_creator
end

post "/:fight_name/new_character" do
  fetch_fight(params[:fight_name])
  name = params[:name].strip

  existing_names = @fight.characters.map(&:name)
  error = valid_name_error(name, existing_names)

  if error
    session[:error] = error
    @title = "Creating New Character in #{@fight.name}"
    @submit_button = "Submit New Character"
    @post_location = "/#{slugify(@fight.name)}/new_character"

    erb :character_creator
  else
    @fight << Character.new(params)
    session[:success] = "New Character Created!"
    redirect "/" + slugify(@fight.name)
  end
end

# Edit Character
get "/:fight_name/:character_name/edit" do
  fetch_fight(params[:fight_name])
  fetch_character(params[:character_name])

  @title = "Editing #{@character.name}"
  @submit_button = "Save Changes"
  @post_location = "/#{slugify(@fight.name, @character.name)}/edit"
  set_edit_character_prefills(@character)
  erb :character_creator
end

post "/:fight_name/:character_name/edit" do
  fetch_fight(params[:fight_name])
  fetch_character(params[:character_name])

  existing_names = @fight.characters.map(&:name)
  existing_names.delete(@character.name)
  error = valid_name_error(params[:name], existing_names)

  if error
    session[:error] = error
    @title = "Editing #{@character.name}"
    @submit_button = "Save Changes"
    @post_location = "/#{slugify(@fight.name, @character.name)}/edit"

    erb :character_creator
  else
    @character.update(params)
    session[:success] = "Character was updated!"
    redirect "/" + slugify(@fight.name)
  end
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

# Add and Remove Conditions
post "/:fight_name/:character_name/add_condition" do
  fetch_fight(params[:fight_name])
  fetch_character(params[:character_name])

  @character.add_condition(params[:condition])

  redirect "/#{slugify(@fight.name)}"
end

get "/:fight_name/:character_name/remove_condition/:condition" do
  fetch_fight(params[:fight_name])
  fetch_character(params[:character_name])

  @character.remove_condition(params[:condition])

  redirect "/#{slugify(@fight.name)}"
end
