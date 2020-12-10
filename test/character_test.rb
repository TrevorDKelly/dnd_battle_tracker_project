require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use!

require_relative '../lib/character'
require_relative 'character_creator_methods'

class FightTest < Minitest::Test
  # helper methods
  include CharacterCreatorMethods

  # Setup

  def setup
    create_npc
  end

  # Tests
  def test_create_npc
    npc = Npc.new('npc', 10)

    assert_equal 'npc', npc.name
    assert_equal 10, npc.hp
  end

  def test_create_player
    player = Player.new('player', 10)

    assert_equal 'player', player.name
    assert_equal 10, player.hp
    assert_equal "Character Created!", player.last_event
  end

  def test_new_character_starting_stats
    assert_equal [], @npc.conditions
    assert_equal 0, @npc.initiative
    assert_equal Integer, @npc.hp.class
    assert @npc.max_hp == @npc.hp
    assert_equal "Character Created!", @npc.last_event
  end

  # Class Methods

  def test_conditions_class_method
    conditions = Character.conditions
    assert_equal Array, conditions.class
    conditions.each do |condition|
      assert_equal String, condition.class
    end
  end

  # Instance Variables with attr_accessor

  def test_name
    assert_equal 'npc', @npc.name

    @npc.name = 'name'

    assert_equal 'name', @npc.name
  end

  def test_char_class
    assert_nil @npc.char_class

    @npc.char_class = 'char_class'

    assert_equal 'char_class', @npc.char_class
  end

  def test_size
    assert_nil @npc.size

    @npc.size = 'size'

    assert_equal 'size', @npc.size
  end

  def test_race
    assert_nil @npc.race

    @npc.race = 'race'

    assert_equal 'race', @npc.race
  end

  def test_notes
    assert_nil @npc.notes

    @npc.notes = 'notes'

    assert_equal 'notes', @npc.notes
  end

  def test_last_event
    assert_equal "Character Created!", @npc.last_event

    @npc.last_event = 'last_event'

    assert_equal 'last_event', @npc.last_event
  end

  # Special Instance Variables setting, changing and access

  def test_hp
    assert_equal 10, @npc.hp
    assert_raises(NoMethodError) { @npc.hp = 20 }
  end

  def test_max_hp
    assert_equal 10, @npc.max_hp

    @npc.max_hp = 20

    assert_equal 20, @npc.max_hp
  end

  def test_max_hp_only_changes_hp_if_full
    create_npc(2)

    @npc_0.take_damage 5
    @npc_0.max_hp = 20
    @npc_1.max_hp = 20

    assert_equal 5, @npc_0.hp
    assert_equal 20, @npc_1.hp
  end

  def test_conditions_instance_method
    assert_raises(NoMethodError) { @npc.conditions = "this" }
    assert_equal Array, @npc.conditions.class
  end

  def test_add_condition
    @npc.add_condition("new")

    assert_equal ["new"], @npc.conditions

    @npc.add_condition("second")

    assert_equal ["new", "second"], @npc.conditions
  end

  def test_add_condition_changes_event
    @npc.add_condition("new")

    assert_equal "Is now new", @npc.last_event
  end

  def test_remove_condition
    @npc.add_condition("new")
    @npc.add_condition("second")

    @npc.remove_condition("new")

    assert_equal ["second"], @npc.conditions

    @npc.remove_condition("second")

    assert_equal [], @npc.conditions
  end

  def test_remove_condition_changes_event_if_condition_exists
    @npc.add_condition("new")
    @npc.remove_condition("not there")

    assert_equal "Is now new", @npc.last_event

    @npc.remove_condition("new")

    assert_equal "Is no longer new", @npc.last_event
  end

  def test_remove_all_conditions
    @npc.add_condition("new")
    @npc.remove_condition("not there")

    @npc.remove_all_conditions

    assert_equal [], @npc.conditions
  end

  def test_remove_all_conditions_creates_event
    @npc.add_condition("new")
    @npc.remove_all_conditions

    assert_equal "Returned to normal condition", @npc.last_event
  end

  # Instance Methods

  def test_is_player?
    create_characters

    assert @player.is_player?
    refute @npc.is_player?
  end

  def test_is_npc?
    create_characters

    refute @player.is_npc?
    assert @npc.is_npc?
  end

  def test_take_damage
    @npc.take_damage(5)

    assert_equal 5, @npc.hp
    assert_equal "Took 5 points of damage!", @npc.last_event
  end

  def test_take_damage_string
    @npc.take_damage('5')

    assert_equal 5, @npc.hp
  end

  def test_take_damage_does_not_go_negative
    @npc.take_damage(15)

    assert_equal 0, @npc.hp
  end

  def test_zero_hp_sets_to_unconsious
    @npc.take_damage(15)

    assert_equal "Has fallen unconscious!", @npc.last_event
    assert_includes @npc.conditions, 'Unconscious'
  end

  def test_full_damage
    @npc.full_damage

    assert_equal 0, @npc.hp
  end

  def test_heal
    @npc.take_damage(5)
    @npc.heal(4)

    assert_equal 9, @npc.hp
  end

  def test_heal_changes_event
    @npc.take_damage(5)
    @npc.heal(4)

    assert_equal "Healed 4 points!", @npc.last_event

    @npc.heal(4)

    assert_equal "Returned to full health!", @npc.last_event
  end

  def test_heal_does_nothing_if_full_health
    @npc.heal(1)
    assert_equal "Character Created!", @npc.last_event
  end

  def test_full_heal
    @npc.full_damage
    @npc.full_heal

    assert_equal 10, @npc.hp
  end

  def test_reset
    @npc.take_damage 5
    @npc.add_condition 'prone'

    @npc.reset

    assert_equal 10, @npc.hp
    assert_empty @npc.conditions
  end

  def test_rest_changes_last_event
    @npc.reset

    assert_equal "Has been reset", @npc.last_event
  end
end
