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
    assert_equal "Fight Created!", fight.last_event
    assert_equal "Order Created", fight.sort_order
  end

  # Class Methods

  def test_sort_order_options
    options = Fight.sort_order_options

    assert_instance_of Array, options
    options.each do |option|
      assert_instance_of String, option
    end
  end

  # Accessor instance variables

  def test_name
    assert_equal 'fight', @fight.name

    @fight.name = 'new'

    assert_equal 'new', @fight.name
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

  def test_sort_order
    assert_equal 'Order Created', @fight.sort_order

    @fight.sort_order = 'Max HP'

    assert_equal 'Max HP', @fight.sort_order
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
    3.times do
      @fight << Character.new({ name: "npc", hp: 10, type: 'npc' })
    end
    @fight << Character.new({ name: "npc(2)", hp: 10, type: 'npc' })

    names = @fight.characters.map(&:name)

    assert_equal 4, names.size
    assert_equal names.uniq, names
  end

  def test_change_character_name_if_taken
    create_fight
    create_npc

    @fight << @npc

    @fight << Character.new({ name: "npc", hp: 10, type: 'npc' })

    @fight << Character.new({ name: "npc", hp: 10, type: 'npc' })

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

  def test_restart
    create_fight(2)

    @fight.characters[0].full_damage
    @fight.characters[1].take_damage(5)
    @fight.characters[1].add_condition('Prone')

    @fight.restart

    assert_equal 'Fight Restarted!', @fight.last_event
    @fight.characters.each do |character|
      assert_equal character.max_hp, character.hp
      assert_empty character.conditions
    end
  end

  def test_each_character_created_order
    create_fight(3)

    characters = []

    @fight.each_character do |character|
      characters << character
    end

    assert_equal @fight.characters, characters
  end

  def test_each_character_alphabetical
    create_fight(3)
    @fight.sort_order = 'Alphabetical'
    @fight.characters[0].name = 'b'
    @fight.characters[1].name = 'c'
    @fight.characters[2].name = 'a'
    names = []

    @fight.each_character do |character|
      names << character.name
    end

    assert_equal ['a', 'b', 'c'], names
  end

  def test_each_character_max_hp
    create_fight(3)
    @fight.sort_order = 'Max HP'
    @fight.characters[0].max_hp = 5
    @fight.characters[1].max_hp = 15
    @fight.characters[2].max_hp = 10
    max_hps = []

    @fight.each_character do |character|
      max_hps << character.max_hp
    end

    assert_equal [15, 10, 5], max_hps
  end

  def test_each_character_remaining_hp
    create_fight(3)
    @fight.sort_order = 'Remaining HP'
    @fight.characters[0].take_damage(5)
    @fight.characters[1].take_damage(2)
    @fight.characters[2].take_damage(3)
    hps = []

    @fight.each_character do |character|
      hps << character.hp
    end

    assert_equal [8, 7, 5], hps
  end
end
