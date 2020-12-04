module CharacterCreatorMethods
  def create_player(number = 1)
    if number == 1
      @player = Player.new('player', 10)
    else
      number.times do |n|
        instance_variable_set("@player_#{n}", Player.new("player_#{n}", 10))
      end
    end
  end

  def create_npc(number = 1)
    if number == 1
      @npc = Npc.new('npc', 10)
    else
      number.times do |n|
        instance_variable_set("@npc_#{n}", Npc.new("npc_#{n}", 10))
      end
    end
  end

  def create_characters(npcs = 1, players = 1)
    create_player(players)
    create_npc(npcs)
  end
end
