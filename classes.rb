class Encounter # someday it'll probably be good to have this be a more generic Encounter class that can handle shops/etc. with combat-specific stuff in its own Combat subclass
    attr_accessor :turn_number
    attr_accessor :enemy_array
    attr_accessor :player

    def initialize player, enemies
        self.turn_number = 1
        self.enemy_array = enemies
        self.player = player

        player.gold = 0
        player.materials = 0
        player.food = 0
        player.fortification = 0
        player.available_actions.shuffle! # this matters because eventually we want to do things that deal with action locations (...maybe?)
    end

    # HUD methods

    def display_enemy_info
        indicator = 1
        enemy_array.each do |enemy|
            puts "[#{indicator}] #{enemy.name}: #{enemy.current_hp}/#{enemy.max_hp} HP"
            if enemy.next_action == "attack"
                puts "#{enemy.name} intends to attack for #{enemy.attack_damage} damage"
            elsif enemy.next_action == "raze"
                target = player.available_actions[enemy.raze_target]
                puts "#{enemy.name} intends to raze #{target.name}"
            end
            indicator += 1
        end
    end

    def show_info
        puts "Turn #{turn_number}"
        puts
        display_enemy_info
        puts
        player.display_status
        puts
    end

    # turn 
    def enemy_turn
        # trigger beginning-of-enemy-turn effects (eventually)
        # enemy actions
        enemy_array.each do |enemy|
            if enemy.next_action == "attack"
                player.enter_to_continue "#{enemy.name} attacks you for #{enemy.attack_damage} damage!"
                player.take_damage enemy.attack_damage
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
        # trigger end-of-enemy-turn effects (eventually)
        # reset for next player turn
        self.turn_number += 1
        player.free_workers = player.max_workers
        player.fortification = 0
        player.available_actions.each do |action|
            if action.razed
                action.razed = false
            else
                action.available = true
            end
        end
    end
end

class Character
    attr_accessor :max_hp
    attr_accessor :current_hp
    attr_accessor :fortification

    def lose_hp loss_value
        self.current_hp -= loss_value
    end

    def get_fuzzy_int average, radius # generates a number distributed uniformly around average +/- radius; e.g. passing 10, 2 will make a number from 8-12
        rng = Random.new
        min = average - radius
        max = average + radius
        rng.rand(min..max)
    end

    def enter_to_continue prompt
        puts prompt
        puts "(press Enter to continue)"
        gets
    end
end

class Player < Character
    attr_accessor :unlocked_phase
    attr_accessor :available_actions
    attr_accessor :max_workers
    attr_accessor :free_workers
    attr_accessor :gold
    attr_accessor :materials
    attr_accessor :food
    attr_accessor :dead

    def initialize
        self.max_hp = 100
        self.current_hp = max_hp
        self.unlocked_phase = 1
        self.max_workers = 2
        self.free_workers = max_workers
    end

    def display_status
        puts "Resources: #{food} Food, #{materials} Materials, #{gold} Gold"
        puts "#{current_hp}/#{max_hp} HP"
        puts "#{fortification} Fortification"
        puts "#{free_workers} workers left until next enemy turn"
        puts
        puts "Available actions:"
        available_actions.each_with_index do |action, index|
            if action.available 
                indicator = index + 1
            else
                indicator = "X"
            end
            puts "[#{indicator}] #{action.name}: #{action.description}"
        end
    end

    def take_damage damage_value
        if damage_value <= self.fortification
            enter_to_continue "#{damage_value} damage blocked!"
            self.fortification -= damage_value
        else
            puts "#{self.fortification} damage blocked!"
            unblocked_damage = damage_value - self.fortification
            self.fortification = 0;
            enter_to_continue "You take #{unblocked_damage} damage!"
            lose_hp unblocked_damage
        end
        return self.current_hp <= 0
    end

    # I/O handling methods

    def get_num_input prompt, max # prompts the user for a number up to max, or returns "quit" if they type "quit" instead
    # probably easier if this just directly selects from an array instead; is there any reason max would be anything other than some_array.length?
    # this... probably belongs in a class higher on the hierarchy?
        puts prompt
        input = gets.chomp
        if input == "quit"
            return input
        elsif input.to_i == 0
            puts "Sorry, didn't quite catch that.  Try again?"
            return get_num_input prompt, max
        elsif input.to_i > max
            puts "Number out of range.  Try again?"
            return get_num_input prompt, max
        else
            return input.to_i
        end
    end

    # action space methods; does it make sense for these to be here? consider: another file?

    def attack combat, damage_value # feels aesthetically off for this to take the combat as an argument, consider moving
        enemy_array = combat.enemy_array
        if enemy_array.length == 1
            target = enemy_array[0]
        else
            combat.display_enemy_info
            target_index = get_num_input "Choose an enemy to attack:" , enemy_array.length
            target = enemy_array[target_index - 1]
        end
        puts "You hit #{target.name} for #{damage_value} damage!"
        target.take_damage damage_value
    end
end

class Enemy < Character
    attr_accessor :next_action
    attr_accessor :last_action
    attr_accessor :name

    def take_damage damage_value
        if damage_value <= self.fortification
            enter_to_continue "#{self.name} blocks #{damage_value} damage!"
            self.fortification -= damage_value
        else
            if self.fortification > 0
                puts "#{self.name} blocks #{self.fortification} damage!"
            end
            unblocked_damage = damage_value - self.fortification
            self.fortification = 0;
            enter_to_continue "#{self.name} takes #{unblocked_damage} damage!"
            lose_hp unblocked_damage
        end
    end

    def decide
        return false
    end
end

class Raider < Enemy
    attr_accessor :attack_damage
    attr_accessor :raze_target

    def decide
        rng = Random.new
        @next_action = ["attack", "raze"].sample
        @attack_damage = get_fuzzy_int 6, 1
        @raze_target = rng.rand(6)
    end

    def initialize
        @max_hp = get_fuzzy_int 25, 2
        @current_hp = max_hp 
        @name = "Raider"
        @fortification = 0
        self.decide
    end
end

class Barbarian < Enemy
    attr_accessor :attack_damage
    
    def initialize
        @max_hp = get_fuzzy_int 30, 5
        @current_hp = max_hp
        @attack_damage = 4
        @name = "Barbarian"
        @fortification = 0
        @next_action = "attack"
    end

    def take_damage damage_value # same as generic take_damage, but increments attack_damage whenever damage is taken; is there a cleaner way to do this? 
        if damage_value <= self.fortification
            enter_to_continue "#{self.name} blocks #{damage_value} damage!"
            self.fortification -= damage_value
        else
            puts "#{self.name} blocks #{self.fortification} damage!"
            unblocked_damage = damage_value - self.fortification
            self.fortification = 0
            enter_to_continue "#{self.name} takes #{unblocked_damage} damage!"
            @attack_damage += 2
            lose_hp unblocked_damage
        end
    end
end

class ActionSpace
    attr_accessor :phase
    attr_accessor :available
    attr_accessor :name
    attr_accessor :description
    attr_accessor :razed

    def initialize phase, name, description
        self.phase = phase
        self.name = name
        self.description = description
        self.available = true
        self.razed = false
    end

    def raze
        self.razed = true
        self.available = false
    end
end