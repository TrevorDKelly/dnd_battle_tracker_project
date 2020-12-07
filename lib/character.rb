require_relative 'name_iterator'

class Character
  attr_reader :name, :hp, :max_hp

  include NameIterator

  def initialize(name, hp)
    @name = name
    @hp = hp.to_i
    @max_hp = @hp
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
  end

  def heal(amount)
    @hp += amount.to_i
    @hp = @hp > @max_hp ? @max_hp : @hp
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
