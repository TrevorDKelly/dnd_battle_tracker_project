require_relative 'character'
require_relative 'name_iterator'

require 'date'

class Fight
  attr_accessor :name, :status, :notes, :last_event
  attr_reader :characters, :dates

  include NameIterator

  def initialize(name)
    @name = name
    @characters = []
    @status = 'Prepping'
    @dates = [Date.today, nil, nil]
    @last_event = "Fight Created!"
  end

  def add_character(name, hp = 1, npc = true)
    new_name = verify_name(name, @characters)

    character = if npc
                  Npc.new(new_name, hp)
                else
                  Player.new(new_name, hp)
                end

    @characters << character
    @last_event = "#{character.name} created!"
    @dates[2] = Date.today
  end

  def <<(character)
    if @characters.map(&:name).include? character.name
      character = character.copy(verify_name(character.name, @characters))
    end

    @characters << character

    @last_event = "#{character.name} created!"
    @dates[2] = Date.today
  end

  def npc_count
    @characters.count(&:is_npc?)
  end

  def player_count
    @characters.count(&:is_player?)
  end

  def duplicate(existing_fights)
    new_name = verify_name(@name, existing_fights)
    fight = Fight.new(new_name)

    @characters.each do |character|
      new_name = verify_name(character.name, fight.characters)
      fight << character.copy(new_name, duplicate: true)
    end

    fight.last_event = 'Fight Created!'
    fight
  end

  def npcs
    @characters.select(&:is_npc?)
  end

  def strongest_npc
    npcs.max { |a, b| a.max_hp <=> b.max_hp }
  end

  def start_fight
    @dates[1] = Date.today
    @dates[2] = Date.today
    @status = "Fight Started!"
    @last_event = "Fight Started!"
  end

  def npc_health_percentage
    return 0 if npcs.empty?
    hp_left = 0
    full_hp = 0

    npcs.each do |npc|
      hp_left += npc.hp
      full_hp += npc.max_hp
    end

    hp_left.to_f/full_hp * 100
  end

  def fetch_character(name)
    @characters.select { |character| character.name == name }.first
  end

  private

  def verify_name(name, existing)
    loop do
      valid = existing.none? { |existing| existing.name == name }
      return name if valid
      name = iterate_name(name)
    end
  end
end
