require_relative 'character'
require_relative 'name_iterator'
require_relative 'event_buffer'

require 'date'

class Fight
  attr_accessor :name, :status, :notes
  attr_reader :characters, :dates, :events

  include NameIterator

  def initialize(name)
    @name = name
    @characters = []
    @status = 'Prepping'
    @dates = [Date.today, nil, nil]
    @events = EventBuffer.new(15)
    @events << "Fight Created!"
  end

  def add_character(name, hp = 1, npc = true)
    character = if npc
                  Npc.new(name, hp)
                else
                  Player.new(name, hp)
                end

    @characters << character
    @events << "#{character.name} created!"
    @dates[2] = Date.today
  end

  def <<(character)
    @characters << character

    @events << "#{character.name} created!"
    @dates[2] = Date.today
  end

  def npc_count
    @characters.count(&:is_npc?)
  end

  def player_count
    @characters.count(&:is_player?)
  end

  def duplicate
    fight = Fight.new(iterate_name)

    @characters.each do |character|
      fight << character.copy(duplicate: true)
    end

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
    @events << "Fight Started!"
  end

  def npc_health_percentage
    return 0 if npcs.empty?
    hp_left = 0
    full_hp = 0

    npcs.each do |npc|
      hp_left += npc.hp
      full_hp += npc.max_hp
    end

    hp_left/full_hp * 100
  end
end
