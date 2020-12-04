require_relative 'character'
require_relative 'name_iterator'

class Fight
  attr_accessor :name, :status
  attr_reader :characters

  include NameIterator

  def initialize(name)
    @name = name
    @characters = []
    @status = 'Prepping'
  end

  def add_character(name, hp = 1, npc = true)
    character = if npc
                  Npc.new(name, hp)
                else
                  Player.new(name, hp)
                end

    @characters << character
  end

  def <<(character)
    @characters << character
  end

  def npc_count
    @characters.count { |char| !char.is_player? }
  end

  def player_count
    @characters.count { |char| char.is_player? }
  end

  def duplicate
    fight = Fight.new(iterate_name)

    @characters.each do |character|
      fight << character.copy(duplicate: true)
    end

    fight
  end
end
