require './classes.rb'

# to do: 
# clean up absolutely everything, God, look at this mess
# wrap death checks into damage-taking functions... somehow
# create separate lose-HP function so fortification can be ignored for upkeep and other types of armor-piercing; this probably will assist in cleanup of player.take_damage also

player = Player.new

puts "Welcome to Untitled Worker Placement Roguelite Project's Alpha version!"
puts "You can type 'quit' at any time to quit the game.  If it's your first time playing, you should read help.txt in the game directory."
player.enter_to_continue "Although I find it hard to imagine that you'd reach this screen without knowing me in real life, so you can also just hit me up and ask if you have questions."

attack = ActionSpace.new 1, "Attack", "Deal 6 damage."
block = ActionSpace.new 1, "Block", "Gain 5 Fortification."
gather = ActionSpace.new 1, "Gather", "Gain 3 Materials."
forage = ActionSpace.new 1, "Forage", "Gain 3 Food."
research = ActionSpace.new 1, "Research", "Pay 10 Materials to unlock new actions. (COMING SOON)"
build = ActionSpace.new 1, "Build", "Pay Materials to permanently expand or improve your village. (COMING SOON)"

player.available_actions = [attack, block, gather, forage, research, build]

combat = Encounter.new player, [Birb.new, Birb.new]

quit = false
while !quit do # main encounter loop
    if player.free_workers > 0 # player turn
        system("cls")
        combat.show_info
        command = player.get_num_input "Select an action:", player.available_actions.length
        if command == "quit"
            puts "Thanks for playing!"
            quit = true
        elsif !player.available_actions[command - 1].available
            player.enter_to_continue "Action unavailable (taken or razed).  Try again?"
        else
            action = player.available_actions[command - 1]
            action.available = false
            player.free_workers -= 1
            # TODO: add literally any modularity to this section
            if action == attack
                player.attack combat, 6
            elsif action == block
                player.fortification += 5
                player.enter_to_continue "You gained 5 Fortification!"
            elsif action == gather
                player.materials += 3
                player.enter_to_continue "You gained 3 Materials!"
            elsif action == forage
                player.food += 3
                player.enter_to_continue "You gained 3 Food!"
            end
            combat.enemy_array.each_with_index do |enemy, index|
                if enemy.current_hp <= 0
                    combat.enemy_array.delete_at(index)
                end
            end
            if combat.enemy_array.length == 0 # if combat is over
                player.fortification = 0
                player.max_workers.times do
                    player.food -= 5
                    if player.food < 0
                        player.enter_to_continue "Failed to feed a worker! You lose 20 HP."
                        player.take_damage 20
                    end
                end
                if player.current_hp < 0 # check if player has died
                    player.enter_to_continue "You have died.  Git gud."
                    quit = true
                else
                    player.enter_to_continue "You win! This is the entire game, congratulations."
                    quit = true
                end
            end
        end
    else # enemy turn section
        combat.enemy_array.each do |enemy|
            if enemy.next_action == "attack"
                player.enter_to_continue "#{enemy.name} attacks you for #{enemy.attack_damage} damage!"
                player.take_damage enemy.attack_damage
                if player.fortification < 0
                    player.fortification = 0
                end
            elsif enemy.next_action == "raze"
                target = player.available_actions[enemy.raze_target]
                player.enter_to_continue "#{enemy.name} razes #{target.name}; it can't be used next turn!"
                target.raze
            end
            if player.current_hp <= 0 # check if player has died
                player.enter_to_continue "You have died.  Git gud."
                quit = true
            end
            enemy.decide
        end
        if player.current_hp > 0 # reset for next turn
            combat.turn_number += 1
            player.free_workers = player.max_workers
            player.fortification = 0
            player.available_actions.each do |action|
                if action.razed
                    action.razed = false
                    puts "#{action.name} has now been unrazed!"
                else
                    action.available = true
                end
            end
        end  
    end
end
