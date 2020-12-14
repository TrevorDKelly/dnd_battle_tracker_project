require_relative 'name_iterator'

class Character
  attr_reader :hp, :max_hp, :conditions, :ability_scores
  attr_accessor :name, :char_class, :size, :race, :notes, :last_event,
                :initiative, :initiative_bonus, :ac, :type

  CONDITIONS = %w(Prone Poisoned Flanked Blinded Restrained Grappled
                  Incapacitated Unconscious)

  include NameIterator

  def initialize(params)
    set_character_stats(params)
    @hp = @max_hp
    @conditions = []
    @last_event = "Character Created!"
  end

  def self.conditions
    CONDITIONS
  end

  def update(params)
    set_character_stats(params)
    @last_event = "Character Updated"
  end

  def max_hp=(new)
    full = @hp == @max_hp

    @max_hp = new
    @hp = @max_hp if (full || @hp > @max_hp)
  end

  def is_player?
    type == 'player'
  end

  def is_npc?
    type == 'npc'
  end

  def take_damage(amount)
    @hp -= amount.to_i
    @hp = 0 if @hp < 0
    @last_event = "Took #{amount} points of damage!"

    if @hp == 0
      add_condition "Unconscious"
      @last_event = "Has fallen unconscious!"
    end
  end

  def full_damage
    take_damage(@max_hp)
  end

  def heal(amount)
    return if @hp == @max_hp
    @hp += amount.to_i
    @hp = @max_hp if @hp > @max_hp
    @last_event = "Healed #{amount} points!"
    @last_event = "Returned to full health!" if @hp == @max_hp
  end

  def full_heal
    heal(@max_hp)
  end

  def add_condition(condition)
    @conditions << condition
    @last_event = "Is now #{condition}"
  end

  def remove_condition(condition)
    has_condition = @conditions.include?(condition)
    @last_event = "Is no longer #{condition}" if has_condition
    @conditions.delete(condition)
  end

  def remove_all_conditions
    @conditions = []
    @last_event = "Returned to normal condition"
  end

  def copy(name)
    npc = self.class == Npc

    if npc
      Npc.new(name, @max_hp)
    else
      Player.new(name, @max_hp)
    end
  end

  def reset
    full_heal
    remove_all_conditions
    @last_event = 'Has been reset'
  end

  private

  def set_character_stats(params)
    @name = params[:name]
    self.max_hp = params[:hp].to_i
    @ac = params[:ac]
    @initiative_bonus = params[:initiative_bonus] || 0
    @char_class = params[:char_class]
    @size = params[:size]
    @race = params[:race]
    @notes = params[:notes]
    @type = params[:type]
    set_ability_scores(params)
  end

  def set_ability_scores(params)
    @ability_scores = {}
    scores = [:strength, :dexterity, :constitution, :intelligence,
              :wisdom, :charisma]

    scores.each do |score|
      @ability_scores[score] = params[score]
    end
  end
end
