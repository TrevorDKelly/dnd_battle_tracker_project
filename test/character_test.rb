require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use!

require_relative '../lib/character'
require_relative 'character_creator_methods'

class FightTest < Minitest::Test
  # helper methods
  include CharacterCreatorMethods

  def count_events(character)
    number = 0
    character.events.each do |_|
      number += 1
    end
    number
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
    assert_equal 1, count_events(player)
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
    assert_equal 2, count_events(@npc)
  end

  def test_take_damage_string
    create_npc
    @npc.take_damage('5')

    assert_equal 5, @npc.hp
    assert_equal 2, count_events(@npc)
  end

  def test_take_damage_does_not_go_negative
    create_npc
    @npc.take_damage(15)

    assert_equal 0, @npc.hp
  end

  def test_heal
    create_npc
    @npc.take_damage(5)
    @npc.heal(4)

    assert_equal 9, @npc.hp
    assert_equal 3, count_events(@npc)
  end

  def test_heal_does_not_excced_max
    create_npc
    @npc.take_damage(5)
    @npc.heal(14)

    assert_equal 10, @npc.hp
  end

  def test_copy
    create_characters

    new_npc = @npc.copy
    new_player = @player.copy

    assert_equal Npc, new_npc.class
    assert_equal Player, new_player.class

    assert_equal 'npc(2)', new_npc.name
    assert_equal 'player(2)', new_player.name

    third_npc = new_npc.copy

    assert_equal 'npc(3)', third_npc.name
  end

  def test_copy_with_special_characters_in_name
    npc = Npc.new('a(1)b(2)c', 10)

    new_npc = npc.copy

    assert_equal 'a(1)b(2)c(2)', new_npc.name
  end

  def test_copy_duplicate
    create_npc

    new_npc = @npc.copy(duplicate: true)

    assert_equal @npc.name, new_npc.name
    assert_equal @npc.hp, new_npc.hp
  end

  def test_get_conditions
    conditions = Character.conditions

    assert_instance_of Array, conditions

    conditions.each do |condition|
      assert_equal String, condition.class
    end
  end

  def test_max_hp
    create_npc

    @npc.max_hp = 15

    assert_equal 15, @npc.max_hp
    assert_equal 15, @npc.hp
  end

  def test_add_conditions
    create_npc

    @npc.add_condition('Prone')

    assert_includes @npc.conditions, 'Prone'
    refute_includes @npc.conditions, 'Normal'
  end

  def test_remove_condition
    create_npc

    @npc.add_condition('Prone')
    @npc.add_condition('Flanked')

    @npc.remove_condition('Prone')

    assert_includes @npc.conditions, 'Flanked'
    refute_includes @npc.conditions, 'Prone'
    refute_includes @npc.conditions, 'Normal'

    @npc.remove_condition('Flanked')

    assert_includes @npc.conditions, 'Normal'
    refute_includes @npc.conditions, 'Flanked'
  end

  def test_full_heal
    create_npc

    @npc.take_damage(5)

    @npc.full_heal

    assert_equal 10, @npc.hp
    assert_equal 3, count_events(@npc)
  end
end
