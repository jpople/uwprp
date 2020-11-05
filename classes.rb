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
        player.available_actions.shuffle! # this matters because eventually we want to do things that deal with action locations (maybe?)
    end

    # HUD methods

    def display_enemy_info
        indicator = 1
        enemy_array.each do |enemy|
            puts "[#{indicator}] #{enemy.name}: #{enemy.current_hp}/#{enemy.max_hp} HP"
            puts "#{enemy.name} intends to attack for #{enemy.attack_damage} damage" # will need to redo this when enemies can do things other than attack, obviously
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
end

class Character
    attr_accessor :max_hp
    attr_accessor :current_hp

    def take_damage damage_value
        self.current_hp -= damage_value
    end

    def get_fuzzy_int average, radius # generates a number distributed uniformly around average +/- radius; e.g. passing 10, 2 will make a number from 8-12
        rng = Random.new
        min = average - radius
        max = average + radius
        rng.rand(min..max)
    end
end

class Player < Character
    attr_accessor :unlocked_phase
    attr_accessor :available_actions
    attr_accessor :max_workers
    attr_accessor :free_workers
    attr_accessor :fortification
    attr_accessor :gold
    attr_accessor :materials
    attr_accessor :food

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

    def take_damage damage_value # this is a mess
        if self.fortification != 0
            puts "#{self.fortification} damage blocked!"    
            self.fortification -= damage_value
            if self.fortification < 0
                enter_to_continue "You take #{-self.fortification} damage!"
                self.current_hp += self.fortification
            else
                enter_to_continue "All damage blocked!"
            end
        else
            self.current_hp -= damage_value
            enter_to_continue "You take #{damage_value} damage!"
        end
    end

    # I/O handling methods

    def get_num_input prompt, max # prompts the user for a number up to max, or returns "quit" if they type "quit" instead
    # probably easier if this just directly selects from an array instead; is there any reason max would be anything other than some_array.length?
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

    def enter_to_continue prompt
        puts prompt
        puts "(press Enter to continue)"
        gets
    end

    # action space methods; does it make sense for these to be here? consider: another file?

    def attack combat, damage_value
        enemy_array = combat.enemy_array
        if enemy_array.length == 1
            target = enemy_array[0]
        else
            combat.display_enemy_info
            target_index = get_num_input "Choose an enemy to attack:" , enemy_array.length
            target = enemy_array[target - 1]
        end
        target.take_damage damage_value
        enter_to_continue "You hit #{target.name} for 6 damage!"
    end
end

class Enemy < Character
    attr_accessor :next_action
    attr_accessor :last_action
    attr_accessor :name
end

class Birb < Enemy
    attr_accessor :attack_damage

    def initialize
        @max_hp = get_fuzzy_int 25, 2
        @current_hp = max_hp
        @next_action = "attack"
        @name = "Birb"
        @attack_damage = get_fuzzy_int 6, 1
    end
end

class EnemyAction # does it make any sense for this to inherit from ActionSpace?
    attr_accessor :name
    attr_accessor :description
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
end