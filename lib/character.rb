require_relative 'name_iterator'

class Character
  attr_reader :hp, :max_hp, :conditions
  attr_accessor :name, :char_class, :size, :race, :notes,
                :last_event, :initiative

  CONDITIONS = %w(Normal Prone Poisoned Flanked Blinded Restrained Grappled Incapacitated Unconscious)

  include NameIterator

  def initialize(name, hp)
    @name = name
    @hp = hp.to_i
    @max_hp = @hp
    @conditions = ["Normal"]
    @initiative = 0
    @last_event = "Character Created!"
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
    @last_event = "Took #{amount} points of damage!"

    if @hp == 0
      add_condition "Unconscious"
      @last_event = "Has fallen unconscious!"
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
    @last_event = "Healed #{amount} points!"
  end

  def full_heal
    @hp = @max_hp
    @last_event = "Returned to full health!"
  end

  def full_damage
    @hp = 0
    @last_event = "Has fallen unconscious!"
  end

  def max_hp=(new)
    @max_hp = new
    @hp = @max_hp
  end

  def copy(name, duplicate: false)
    npc = self.class == Npc

    if npc
      Npc.new(name, @max_hp)
    else
      Player.new(name, @max_hp)
    end
  end

  def reset
    full_heal
    @conditions = ['Normal']
    @last_event = 'Has been reset'
  end
end

class Player < Character

end

class Npc < Character

end
