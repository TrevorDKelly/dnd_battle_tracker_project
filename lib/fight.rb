require_relative 'character'
require_relative 'name_iterator'

class Fight
  attr_accessor :name, :notes, :last_event, :sort_order
  attr_reader :characters

  include NameIterator

  SORT_OPTIONS = ['Alphabetical', 'Reverse Alphabetical', 'Highest Max HP',
                  'Lowest Max HP', 'Highest Remaining HP',
                  'Lowest Remaining HP', 'Order Created',
                  'Reverse Order Created']

  def initialize(name)
    @name = name
    @characters = []
    @sort_order = 'Order Created'
    @last_event = "Fight Created!"
  end

  def self.sort_options
    SORT_OPTIONS
  end

  def <<(character)
    if @characters.map(&:name).include? character.name
      character = character.copy(verify_name(character.name, @characters))
    end

    @characters << character

    @last_event = "#{character.name} created!"
  end

  def npc_count
    @characters.count(&:is_npc?)
  end

  def player_count
    @characters.count(&:is_player?)
  end

  def duplicate(existing_fights)
    new_name = verify_name(@name, existing_fights)
    fight = Fight.new(new_name)

    @characters.each do |character|
      new_name = verify_name(character.name, fight.characters)
      fight << character.copy(new_name)
    end

    fight.last_event = 'Fight Created!'
    fight
  end

  def npcs
    @characters.select(&:is_npc?)
  end

  def strongest_npc
    npcs.max { |a, b| a.max_hp <=> b.max_hp }
  end

  def npc_health_percentage
    return 0 if npcs.empty?
    hp_left = 0
    full_hp = 0

    npcs.each do |npc|
      hp_left += npc.hp
      full_hp += npc.max_hp
    end

    hp_left.to_f/full_hp * 100
  end

  def fetch_character(name)
    @characters.select { |character| character.name == name }.first
  end

  def restart
    @characters.each do |character|
      character.full_heal
      character.remove_all_conditions
    end
    @last_event = "Fight Restarted!"
  end

  def each_character
    chars = if sort_order.include? 'Order Created'
              @characters
            else
              @characters.sort do |a, b|
                sort_value(a) <=> sort_value(b)
              end
            end
    chars = chars.reverse if sort_order =~ /(Reverse|Highest)/

    chars.each { |character| yield(character) }
  end

  private

  def sort_value(character)
    case sort_order.sub(/(Reverse |Lowest |Highest )/, '')
    when 'Alphabetical' then character.name
    when 'Max HP'       then character.max_hp
    when 'Remaining HP' then character.hp
    end
  end

  def verify_name(name, existing)
    loop do
      valid = existing.none? { |existing| existing.name == name }
      return name if valid
      name = iterate_name(name)
    end
  end
end
