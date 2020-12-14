module CharacterCreatorMethods
  def create_player(number = 1)
    params = {name: 'player', hp: 10, type: 'player'}

    if number == 1
      @player = Character.new(params)
    else
      number.times do |n|
        params[:name] = "player_#{n}"
        instance_variable_set("@player_#{n}", Character.new(params))
      end
    end
  end

  def create_npc(number = 1)
    params = {name: 'npc', hp: 10, type: 'npc'}
    if number == 1
      @npc = Character.new(params)
    else
      number.times do |n|
        params[:name] = "npc_#{n}"
        instance_variable_set("@npc_#{n}", Character.new(params))
      end
    end
  end

  def create_characters(npcs = 1, players = 1)
    create_player(players)
    create_npc(npcs)
  end
end
