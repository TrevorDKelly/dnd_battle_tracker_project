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
      @fight << Character.new({ name: "npc_#{n}", hp: 10, type: 'npc'} )
    end

    players.times do |n|
      @fight << Character.new({ name: "player_#{n}", hp: 10, type: 'player'} )
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
    skip
    3.times do
      @fight << Character.new({ name: "npc", hp: 10, type: 'npc' })
    end
    @fight << Character.new({ name: "npc(2)", hp: 10, type: 'npc' })

    names = @fight.characters.map(&:name)

    assert_equal 4, names.size
    assert_equal names.uniq, names
  end

  def test_change_character_name_if_taken
    skip
    create_fight
    create_npc

    @fight << @npc

    @fight << Character.new({ name: "npc", hp: 10, type: 'npc' })

    @fight.add_character('npc', 10)

    assert_equal 'npc(2)', @fight.characters[1].name
    assert_equal 'npc(3)', @fight.characters[2].name
  end

  # Duplicate Fight

  def test_duplicate_fight
    skip
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
    skip
    create_fight(2, 2)

    @fight.characters.each { |character| character.take_damage(5) }

    new_fight = @fight.duplicate([@fight])

    new_fight.characters.each do |character|
      assert_equal character.max_hp, character.hp
    end
  end

  def test_duplicate_returns_fight_object
    skip
    create_fight(2, 2)

    new_fight = @fight.duplicate([@fight])

    assert_equal Fight, new_fight.class
  end

  def test_duplicating_fight_does_not_reuse_name
    skip
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

    strongest = Character.new({ name: "strong", hp: 100, type: 'npc' })
    weak = Character.new({ name: "weak", hp: 10, type: 'npc' })
    player = Character.new({ name: "npc", hp: 110, type: 'player' })

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
    create_characters(2, 1)

    assert_equal 0, @fight.npc_count

    @fight << @npc_0
    assert_equal 1, @fight.npc_count

    @fight << @player
    assert_equal 1, @fight.npc_count

    @fight << @npc_1
    assert_equal 2, @fight.npc_count
  end

  def test_player_count
    create_characters(1, 2)

    assert_equal 0, @fight.player_count

    @fight << @player_0
    assert_equal 1, @fight.player_count

    @fight << @npc
    assert_equal 1, @fight.player_count

    @fight << @player_1
    assert_equal 2, @fight.player_count
  end

  def test_npc_health_percentage
    create_characters(2, 1)

    assert_equal 0, @fight.npc_health_percentage

    @fight << @npc_0
    assert_equal 100.0, @fight.npc_health_percentage

    @fight << @player
    @fight.characters[1].full_damage
    assert_equal 100.0, @fight.npc_health_percentage

    @fight << @npc_1
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
