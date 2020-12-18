require_relative 'name_iterator'

class Character
  attr_reader :hp, :max_hp, :conditions, :ability_scores
  attr_accessor :name, :char_class, :size, :race, :notes, :last_event,
                :initiative, :initiative_bonus, :ac, :type, :alignment

  CONDITIONS = %w(Blinded Charmed Deafened Frightened Grappled Incapacitated
                  Invisible Paralyzed Petrified Poisoned Prone Restrained
                  Stunned Unconscious Confused Concentrating Dead Dying
                  Fatigued Flat-Footed Helpless Stable Asleep).sort

  include NameIterator

  def initialize(params)
    @max_hp = params[:hp].to_i
    @hp = @max_hp
    set_character_stats(params)
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
    @last_event = "Took #{amount} points of damage!"

    if @hp < 1
      add_condition "Unconscious"
      @last_event = "Has fallen unconscious!"
    end
  end

  def full_damage
    take_damage(@hp) unless @hp < 1
  end

  def heal(amount)
    return if @hp == @max_hp

    @hp += amount.to_i
    remove_condition('Unconscious') if @hp > 0

    @hp = @max_hp if @hp > @max_hp
    @last_event = "Healed #{amount} points!"
    @last_event = "Returned to full health!" if @hp == @max_hp
  end

  def full_heal
    amount = @max_hp - @hp
    heal(amount)
  end

  def add_condition(condition)
    return if @conditions.include?(condition) || condition.empty?
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
  end

  def copy(name)
    character = Character.new({})
    instance_variables.each do |i_var|
      value = instance_variable_get(i_var)

      character.instance_variable_set(i_var, value)
    end

    character.name = name
    character.reset
    character.last_event = "Character Created!"

    character
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
    @initiative_bonus = params[:initiative_bonus]
    @char_class = params[:char_class]
    @size = params[:size]
    @race = params[:race]
    @notes = params[:notes]
    @type = params[:type]
    @alignment = params[:alignment]
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
