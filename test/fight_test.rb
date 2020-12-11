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

  # Setup

  def setup
    create_fight
  end

  # Tests

  def test_create_fight
    fight = Fight.new("battle")

    assert_equal "battle", fight.name
    assert_empty fight.characters
    assert_equal "Prepping", fight.status
    assert_equal "Fight Created!", fight.last_event
  end

  # Accessor instance variables

  def test_name
    assert_equal 'fight', @fight.name

    @fight.name = 'new'

    assert_equal 'new', @fight.name
  end

  def test_status
    assert_equal 'Prepping', @fight.status

    @fight.status = 'status'

    assert_equal 'status', @fight.status
  end

  def test_last_event
    assert_equal "Fight Created!", @fight.last_event

    @fight.last_event = 'last_event'

    assert_equal 'last_event', @fight.last_event
  end

  def test_notes
    assert_nil @fight.notes

    @fight.notes = 'notes'

    assert_equal 'notes', @fight.notes
  end

  # Attr Reader Instance Variables

  def test_characters
    assert_equal [], @fight.characters
    assert_raises(NoMethodError) { @fight.characters = 'this' }
  end

  # Add and Remove characters

  def test_add_charcter_with_npc_default
    @fight.add_character('npc', 10)

    assert_equal 1, @fight.characters.size
    assert_equal Npc, @fight.characters[0].class
  end

  def test_add_player_character
    @fight.add_character('player', 10, :player)

    assert_equal 1, @fight.characters.size
    assert_equal Player, @fight.characters[0].class
  end

  def test_add_character_changes_last_event
    @fight.add_character('npc', 10)

    assert_equal "npc created!", @fight.last_event
  end

  def test_add_multiple_characters
    @fight.add_character('player', 10, :player)
    @fight.add_character('npc', 10)

    assert_equal 2, @fight.characters.size
  end

  def test_add_character_wont_duplicate_name
    3.times { @fight.add_character('npc', 10) }
    @fight.add_character('npc(1)', 10)

    names = @fight.characters.map(&:name)

    assert_equal 4, names.size
    assert_equal names.uniq, names
  end

  def test_shovel
    create_npc

    @fight << @npc

    assert_equal 1, @fight.characters.size
    assert_includes @fight.characters, @npc
  end

  def test_shovel_chages_last_event
    create_npc

    @fight << @npc

    assert_equal "npc created!", @fight.last_event
  end

  def test_shovel_wont_duplicate_name
    3.times { @fight << Npc.new('npc', 10) }
    @fight << Npc.new('npc(1)', 10)

    names = @fight.characters.map(&:name)

    assert_equal 4, names.size
    assert_equal names.uniq, names
  end

  def test_change_character_name_if_taken
    create_fight
    create_npc

    @fight << @npc

    @fight << Npc.new('npc', 10)

    @fight.add_character('npc', 10)

    assert_equal 'npc(2)', @fight.characters[1].name
    assert_equal 'npc(3)', @fight.characters[2].name
  end

  # Duplicate Fight

  def test_duplicate_fight
    create_fight(2, 2)

    new_fight = @fight.duplicate([@fight])

    assert_equal @fight.characters.size, new_fight.characters.size

    @fight.characters.each_with_index do |character, index|
      new_character = new_fight.characters[index]

      assert_equal character.name, new_character.name
      refute_same character, new_character

      assert_equal character.instance_variables,
                   new_character.instance_variables
    end
  end

  def test_duplicate_fight_hp_reset
    create_fight(2, 2)

    @fight.characters.each { |character| character.take_damage(5) }

    new_fight = @fight.duplicate([@fight])

    new_fight.characters.each do |character|
      assert_equal character.max_hp, character.hp
    end
  end

  def test_duplicate_returns_fight_object
    create_fight(2, 2)

    new_fight = @fight.duplicate([@fight])

    assert_equal Fight, new_fight.class
  end

  def test_duplicating_fight_does_not_reuse_name
    create_fight(2, 2)

    fight2 = @fight.duplicate([@fight])
    fights = [@fight, fight2]
    fight3 = fight2.duplicate(fights)
    fights << fight3
    fight4 = @fight.duplicate(fights)

    assert_equal "fight(2)", fight2.name
    assert_equal "fight(3)", fight3.name
    assert_equal "fight(4)", fight4.name
  end

  # Character Retreival

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

  def test_fetch_character
    create_fight(2)

    character1 = @fight.fetch_character('npc_0')
    character2 = @fight.fetch_character('npc_1')

    assert_equal 'npc_0', character1.name
    assert_equal 'npc_1', character2.name
  end

  def test_npc_count
    assert_equal 0, @fight.npc_count

    @fight.add_character('npc', 10)
    assert_equal 1, @fight.npc_count

    @fight.add_character('player', 10, :player)
    assert_equal 1, @fight.npc_count

    @fight.add_character('npc', 10)
    assert_equal 2, @fight.npc_count
  end

  def test_player_count
    assert_equal 0, @fight.player_count

    @fight.add_character('player', 10, :player)
    assert_equal 1, @fight.player_count

    @fight.add_character('npc', 10)
    assert_equal 1, @fight.player_count

    @fight.add_character('player', 10, :player)
    assert_equal 2, @fight.player_count
  end

  def test_npc_health_percentage
    assert_equal 0, @fight.npc_health_percentage

    @fight.add_character('npc', 10)
    assert_equal 100.0, @fight.npc_health_percentage

    @fight.add_character('player', 10, :player)
    @fight.characters[1].full_damage
    assert_equal 100.0, @fight.npc_health_percentage

    @fight.add_character('npc', 10)
    @fight.characters[2].full_damage
    assert_equal 50.0, @fight.npc_health_percentage
  end

  def test_start
    @fight.start

    assert_equal "Fight Started!", @fight.status

    assert_equal "Fight Started!", @fight.last_event
  end

  def test_restart
    create_fight(2)

    @fight.start
    @fight.characters[0].full_damage
    @fight.characters[1].take_damage(5)
    @fight.characters[1].add_condition('Prone')

    @fight.restart

    assert_equal 'Prepping', @fight.status
    assert_equal 'Fight Restarted!', @fight.last_event
    @fight.characters.each do |character|
      assert_equal character.max_hp, character.hp
      assert_empty character.conditions
    end
  end
end
