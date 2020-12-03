require_relative 'character'

class Fight
  attr_accessor :name
  attr_reader :characters

  def initialize(name)
    @name = name
    @characters = []
  end

  def add_character(name, hp, npc = true)
    character = if npc
                  Character.new(name, hp)
                else
                  Player.new(name, hp)
                end

    @characters << character
  end
end
