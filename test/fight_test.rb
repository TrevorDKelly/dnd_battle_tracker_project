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

  def count_events(fight)
    number = 0
    fight.events.each do |event|
      number += 1
    end
    number
  end

  # Tests
  def test_create_fight
    fight = Fight.new("battle")

    assert_equal "battle", fight.name
    assert_equal [], fight.characters
    assert_equal "Prepping", fight.status
    assert_equal Date.today, fight.dates[0]
  end

  def test_create_fight_creates_event
    create_fight

    @fight.events.each do |event|
      assert_equal "Fight Created!", event
    end
  end

  def test_add_charcter_with_npc_default
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

  def test_add_character_adds_event
    create_fight

    @fight.add_character('npc', 10)

    assert_equal 2, count_events(@fight)
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

  def test_shovel_adds_event
    create_fight
    create_npc

    @fight << @npc

    assert_equal 2, count_events(@fight)
  end

  def test_duplicate_fight
    create_fight(2, 2)

    new_fight = @fight.duplicate

    assert_equal @fight.characters.size, new_fight.characters.size

    @fight.characters.each_with_index do |character, index|
      new_character = new_fight.characters[index]

      assert_equal character.name, new_character.name
      refute_same character, new_character

      assert_equal character.instance_variables, new_character.instance_variables
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

  def test_duplicate_returns_fight_object
    create_fight(2, 2)

    new_fight = @fight.duplicate

    assert_equal Fight, new_fight.class
  end

  def test_npcs
    create_fight
    create_characters(2, 2)

    [@npc_0, @npc_1, @player_0, @player_1].each { |char| @fight << char }

    npcs = @fight.npcs

    assert_instance_of Array, npcs
    assert_includes npcs, @npc_0
    assert_includes npcs, @npc_1
    refute_includes npcs, @player_0
    refute_includes npcs, @player_1
  end

  def test_strongest_npc
    create_fight

    assert_nil @fight.strongest_npc

    strongest = Npc.new("strong", 100)
    weak = Npc.new("weak", 10)
    player = Player.new("player", 200)

    [strongest, weak, player].each { |char| @fight << char }

    assert_equal strongest, @fight.strongest_npc
  end

  def test_start_fight
    create_fight

    @fight.start_fight

    assert_equal Date.today, @fight.dates[1]
    assert_equal "Fight Started!", @fight.status

    assert_equal 2, count_events(@fight)
  end
end
