require_relative 'name_iterator'
require_relative 'event_buffer'

class Character
  attr_reader :hp, :max_hp
  attr_accessor :name, :char_class, :size, :race, :state, :notes, :events

  STATES = %w(Normal Prone Poisoned Flanked Blinded Restrained Grappled Incapacutated)

  include NameIterator

  def initialize(name, hp)
    @name = name
    @hp = hp.to_i
    @max_hp = @hp
    @state = "Normal"
    @size = "Medium"
    @events = EventBuffer.new(3)
    @events << "Character Created!"
  end

  def self.states
    STATES
  end

  def is_player?
    self.class == Player
  end

  def is_npc?
    self.class == Npc
  end

  def take_damage(amount)
    @hp -= amount.to_i
    @hp = @hp <= 0 ? 0 : @hp
    @events << "Took #{amount} points of damage!"
  end

  def heal(amount)
    @hp += amount.to_i
    @hp = @hp > @max_hp ? @max_hp : @hp
    @events << "Healed #{amount} points!"
  end

  def copy(duplicate: false)
    npc = self.class == Npc

    new_name = duplicate ? @name.clone : iterate_name

    if npc
      Npc.new(new_name, @max_hp)
    else
      Player.new(new_name, @max_hp)
    end
  end
end

class Player < Character

end

class Npc < Character

end
