require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use!

require_relative '../lib/fight'
require_relative 'character_creator_methods'

class FightTest < Minitest::Test
  # helper methods
  include CharacterCreatorMethods

  def create_fight(npcs = 0, players = 0)
    @fight = Fight.new('fight')

    npcs.times do |n|
      @fight << Npc.new("npc_#{n}", 10)
    end

    players.times do |n|
      @fight << Player.new("player_#{n}", 10)
    end
  end

  # Tests
  def test_create_fight
    fight = Fight.new("battle")

    assert_equal "battle", fight.name
    assert_equal [], fight.characters
    assert_equal "Prepping", fight.status
  end

  def test_add_charcter
    create_fight

    @fight.add_character('npc', 10)

    assert_equal 1, @fight.characters.size
    assert_equal Npc, @fight.characters[0].class
  end

  def test_add_player_character
    create_fight

    @fight.add_character('player', 10, false)

    assert_equal 1, @fight.characters.size
    assert_equal Player, @fight.characters[0].class
  end

  def test_add_multiple_characters
    create_fight

    @fight.add_character('player', 10, false)
    @fight.add_character('npc', 10)

    assert_equal 2, @fight.characters.size
    assert_equal Player, @fight.characters[0].class
  end

  def test_shovel
    create_fight
    create_npc

    @fight << @npc

    assert_equal 1, @fight.characters.size
    assert_includes @fight.characters, @npc
  end

  def test_duplicate_fight
    create_fight(2, 2)

    new_fight = @fight.duplicate

    assert_equal Fight, new_fight.class
    assert_equal @fight.characters.size, new_fight.characters.size

    @fight.characters.each_with_index do |character, index|
      new_character = new_fight.characters[index]

      assert_equal character.name, new_character.name
      refute_same character, new_character
    end
  end

  def test_duplicate_fight_hp_reset
    create_fight(2, 2)

    @fight.characters.each { |character| character.take_damage(5) }

    new_fight = @fight.duplicate

    new_fight.characters.each do |character|
      assert_equal character.max_hp, character.hp
    end
  end
end
