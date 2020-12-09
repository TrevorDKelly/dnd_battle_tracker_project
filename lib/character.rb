require_relative 'name_iterator'
require_relative 'event_buffer'

class Character
  attr_reader :hp, :max_hp, :conditions
  attr_accessor :name, :char_class, :size, :race, :notes,
                :events, :initiative

  CONDITIONS = %w(Normal Prone Poisoned Flanked Blinded Restrained Grappled Incapacitated Unconscious)

  include NameIterator

  def initialize(name, hp)
    @name = name
    @hp = hp.to_i
    @max_hp = @hp
    @conditions = ["Normal"]
    @initiative = 0
    @events = EventBuffer.new(3)
    @events << "Character Created!"
  end

  def self.conditions
    CONDITIONS
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

    if @hp == 0
      add_condition "Unconscious"
      @events << "#{@name} has fallen unconscious!"
    end
  end

  def add_condition(condition)
    @conditions << condition
    @conditions.delete('Normal')
  end

  def remove_condition(condition)
    @conditions.delete(condition)
    @conditions << 'Normal' if @conditions.empty?
  end

  def heal(amount)
    @hp += amount.to_i
    @hp = @hp > @max_hp ? @max_hp : @hp
    @events << "Healed #{amount} points!"
  end

  def full_heal
    @hp = @max_hp
    @events << "Returned to full health!"
  end

  def max_hp=(new)
    @max_hp = new
    @hp = @max_hp
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
