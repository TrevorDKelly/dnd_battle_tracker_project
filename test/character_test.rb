require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use!

require_relative '../lib/character'
require_relative 'character_creator_methods'

class FightTest < Minitest::Test
  # helper methods
  include CharacterCreatorMethods

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
    create_npc

    assert_equal ['Normal'], @npc.conditions
    assert_equal 0, @npc.initiative
  end

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
    create_npc
    @npc.take_damage(5)

    assert_equal 5, @npc.hp
    assert_equal "Took 5 points of damage!", @npc.last_event
  end

  def test_take_damage_string
    create_npc
    @npc.take_damage('5')

    assert_equal 5, @npc.hp
  end

  def test_take_damage_does_not_go_negative
    create_npc
    @npc.take_damage(15)

    assert_equal 0, @npc.hp
    assert_equal "Has fallen unconscious!", @npc.last_event
  end

  def test_heal
    create_npc
    @npc.take_damage(5)
    @npc.heal(4)

    assert_equal 9, @npc.hp
    assert_equal "Healed 4 points!", @npc.last_event
  end
end
