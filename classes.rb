class Encounter
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
        player.available_actions.shuffle!
    end

    def show_info
        puts "Turn #{turn_number}"
        puts
        enemy_array.each do |enemy|
            puts "#{enemy.name}: #{enemy.current_hp}/#{enemy.max_hp} HP"
            puts "#{enemy.name} intends to attack for #{enemy.attack_damage} damage" # will need to redo this when enemies can do things other than attack, obviously
        end
        puts
        puts "Resources: #{player.food} Food, #{player.materials} Materials, #{player.gold} Gold"
        puts "#{player.current_hp}/#{player.max_hp} HP"
        puts "#{player.fortification} Fortification"
        puts "#{player.free_workers} workers left until next enemy turn"
        puts
        puts "Available actions:"
        player.available_actions.each_with_index do |action, index|
            if action.available 
                indicator = index + 1
            else
                indicator = "X"
            end
            puts "[#{indicator}] #{action.name}: #{action.description}"
        end
        puts
    end
end

class Character
    attr_accessor :max_hp
    attr_accessor :current_hp

    def take_damage damage_value
        self.current_hp -= damage_value
    end

    def get_fuzzy_int average, radius # generates a number that will on average be X but is distributed uniformly +/- radius; e.g. passing 10, 2 will make a number from 8-12 with all results being equally likely
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

    def get_num_input prompt, max # prompts the user for a number up to max, or returns "quit" if they type "quit" instead
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
end

class Enemy < Character
    attr_accessor :next_action
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

class EnemyAction # should this just inherit from ActionSpace?
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