class Character
  attr_reader :name, :hp

  def initialize(name, hp)
    @name = name
    @hp = hp.to_i
    @max_hp = @hp
  end

  def is_player?
    self.class == "Player"
  end

  def take_damage(amount)
    @hp -= amount.to_i
    @hp = @hp <= 0 ? 0 : @hp
  end

  def heal(amount)
    @hp += amount.to_i
    @hp = @hp > @max_hp ? @max_hp : @hp
  end
end

class Player < Character

end
