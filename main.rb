require './classes.rb'

# to do: 
# continue cleanup; wrap player turn loop into Encounter class method somehow probably?
# add Build
# add support for multiple sequential combats
# add shop
# add boss
# wrap death checks into damage-taking functions

player = Player.new

puts "Welcome to Untitled Worker Placement Roguelite Project's pre-Alpha version!"
puts "You can type 'quit' at any time to quit the game.  If it's your first time playing, you should read help.txt in the game directory."
player.enter_to_continue "Although I find it hard to imagine that you'd reach this screen without knowing me in real life, so you can also just hit me up and ask if you have questions."

attack = ActionSpace.new 1, "Attack", "Deal 6 damage."
block = ActionSpace.new 1, "Block", "Gain 5 Fortification."
gather = ActionSpace.new 1, "Gather", "Gain 3 Materials."
forage = ActionSpace.new 1, "Forage", "Gain 3 Food."
research = ActionSpace.new 1, "Research", "Pay 10 Materials to unlock new actions."
build = ActionSpace.new 1, "Build", "Pay Materials to permanently expand or improve your village. (COMING SOON)"
train = ActionSpace.new 2, "Train", "Gain 1 additional worker this combat."
scout = ActionSpace.new 2, "Scout", "Deal 3 damage to an enemy and gain 3 Fortification."

all_actions = [attack, block, gather, forage, research, build, train, scout]
player.available_actions = [attack, block, gather, forage, research, build]

enemies = [Raider.new, Raider.new, Barbarian.new, Barbarian.new].sample(2)

combat = Encounter.new player, enemies

quit = false
while !quit do # main combat loop
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
            elsif action == research # should probably have a check to see if more actions can be unlocked at all
                if player.materials < 10 # probably a better way to handle this
                    player.enter_to_continue "Not enough Materials!"
                    player.free_workers += 1
                    action.available = true
                else
                    player.materials -= 10
                    player.unlocked_phase += 1
                    all_actions.each do |action|
                        if action.phase == player.unlocked_phase
                            player.available_actions << action
                            puts "#{action.name} unlocked!"
                        end
                    end
                end
            elsif action == train
                player.max_workers += 1
                player.enter_to_continue "You gained 1 worker!"
            elsif action == scout
                player.fortification += 3
                puts "You gained 3 Fortification!"
                player.attack combat, 3
            end
            combat.enemy_array.each_with_index do |enemy, index| # this probably breaks if multiple enemies die at the same time
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
                        player.lose_hp 20
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
    else
        combat.enemy_turn
    end
end
