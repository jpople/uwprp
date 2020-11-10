# GENERIC STRUCTURAL CLASSES
class Game
    attr_accessor :current_floor

    def initialize
        self.current_floor = 1
    end

    # generic I/O; Encounter and Character have to inherit from Game mainly to have access to these, which seems a bit awkward?

    def get_fuzzy_int center, radius # generates a random number distributed uniformly in a range around the center; e.g. passing 10, 2, gets a random x chosen from 8, 9, 10, 11, 12
        rng = Random.new
        min = center - radius
        max = center + radius
        rng.rand(min..max)
    end

    def select_from array, prompt
        puts prompt
        input = gets.chomp
        if input == "quit"
            quit
        elsif input != "0" && input.to_i == 0
            puts "Sorry, didn't quite catch that. Try again?"
            return select_from array, prompt
        end
        target_index = input.to_i - 1
        if target_index < 0 || target_index > array.length 
            puts "Number out of range.  Try again?"
            return select_from array, prompt
        else
            return array[target_index]
        end
    end

    def enter_to_continue prompt
        puts prompt
        puts "(press Enter to continue)"
        gets
    end

    # game end conditions
    def quit
        puts "You have quit!"
        puts "(press Enter to exit)"
        gets
        exit
    end

    def loss_screen
        puts "You have died!"
        puts "You were defeated on floor #{current_floor}.  Git gud."
        puts "(press Enter to exit)"
        gets
        exit
    end

    def win_screen
        puts "You win!"
        puts "(press Enter to exit)"
        gets
        exit
    end
end

class Encounter < Game # might not need to exist?
end

class Combat < Encounter
    attr_accessor :turn_number
    attr_accessor :player
    attr_accessor :living_enemies

    def initialize player, enemy
        self.turn_number = 0
        self.living_enemies = enemy
        self.player = player

        player.materials = 0
        player.food = 0
        player.fortification = 0

        player.attack.combat = self
        player.scout.combat = self

        living_enemies.each do |enemy|
            enemy.decide
        end
    end

    def run
        cleanup
        while living_enemies.length > 0 do
            while player.free_workers > 0 do
                player_turn
            end
            if living_enemies.length > 0
                enemy_turn
            end
            cleanup
        end
        post_combat
    end

    # combat HUD
    def display_enemy_info
        indicator = 1
        living_enemies.each do |enemy|
            puts "[#{indicator}] #{enemy.name}: #{enemy.current_hp}/#{enemy.max_hp} HP"
            puts enemy.next_action.intent_string
            indicator += 1
        end
    end

    def display_player_info
        puts "Resources: #{player.food} Food, #{player.materials} Materials, #{player.gold} Gold"
        puts "#{player.houses} Houses"
        puts "#{player.current_hp}/#{player.max_hp} HP"
        if player.fortification > 0
            puts "#{player.fortification} Fortification"
        end
        puts "#{player.free_workers}/#{player.max_workers} workers remaining before next enemy turn"
        puts
        puts "Available actions:"
        player.action_spaces.each_with_index do |action, index|
            if action.available
                indicator = index + 1
            else
                indicator = "X"
            end
            puts "[#{indicator}] #{action.name}: #{action.description}"
        end
    end

    def combat_screen
        puts "Turn #{turn_number}"
        puts
        display_enemy_info
        puts
        display_player_info
        puts
    end

    # combat phases

    def player_turn
        system("cls") || system("clear")
        combat_screen
        action = select_from player.action_spaces, "Choose an action:"
        if !action.available
            enter_to_continue "Action unavailable.  Try again?"
        else
            player.free_workers -= 1
            action.available = false
            action.execute
        end
        living_enemies.each_with_index do |enemy, index| # this probably needs to be redone to be able to handle multiple enemies dying at the same time
            if enemy.current_hp <= 0
                living_enemies.delete_at index
            end
        end
    end

    def enemy_turn
        living_enemies.each do |enemy|
            enemy.next_action.execute
            enemy.decide
        end
    end

    def cleanup
        self.turn_number += 1
        player.free_workers = player.max_workers
        player.fortification = 0
        player.action_spaces.each do |action|
            if action.razed
                action.razed = false
            else
                action.available = true
            end
        end
    end

    def post_combat
        player.fortification = 0
        player.max_workers.times do
            player.food -= 5
            if player.food < 0
                enter_to_continue "Failed to feed a worker! You lose 10 HP."
                player.lose_hp 10
            end
        end
        gold_reward = get_fuzzy_int 10, 2
        player.gold += gold_reward
        enter_to_continue "You get #{gold_reward} gold!"
    end
end

class Character < Game
    attr_accessor :max_hp
    attr_accessor :current_hp
    attr_accessor :fortification

    def lose_hp loss_value
        self.current_hp -= loss_value
    end
end

class Player < Character
    # action management attributes
    attr_accessor :unlocked_phase
    attr_accessor :all_actions
    attr_accessor :action_spaces # only those that are unlocked and actually usable 
    # worker management attributes
    attr_accessor :houses
    attr_accessor :max_workers
    attr_accessor :free_workers
    # resource attributes
    attr_accessor :gold
    attr_accessor :materials
    attr_accessor :food
    # action spaces
    attr_accessor :attack
    attr_accessor :block
    attr_accessor :gather
    attr_accessor :forage
    attr_accessor :research
    attr_accessor :build
    attr_accessor :train
    attr_accessor :scout

    def initialize        
        self.max_hp = 100
        self.current_hp = max_hp
        self.unlocked_phase = 1
        
        self.attack = Attack.new 
        self.block = Block.new self
        self.gather = Gather.new self
        self.forage = Forage.new self
        self.research = Research.new self
        self.train = Train.new self
        self.scout = Scout.new self
        self.build = Build.new self

        self.all_actions = [attack, block, gather, forage, research, train, scout, build]
        self.action_spaces = [attack, block, gather, forage, research]

        self.houses = 2
        self.max_workers = houses
        self.free_workers = max_workers
        self.gold = 0
        self.materials = 0
    end

    def lose_hp loss_value
        self.current_hp -= loss_value
        if current_hp < 0
            loss_screen
        end
    end

    def take_damage damage_value
        if damage_value <= self.fortification
            enter_to_continue "#{damage_value} damage blocked!"
            self.fortification -= damage_value
        else
            puts "#{self.fortification} damage blocked!"
            unblocked_damage = damage_value - self.fortification
            self.fortification = 0
            enter_to_continue "You take #{unblocked_damage} damage!"
            lose_hp unblocked_damage
        end
    end
end

class Enemy < Character
    attr_accessor :next_action
    attr_accessor :last_action
    attr_accessor :name

    def take_damage damage_value # seems pretty awkward that this method is exactly the same as Player.take_damage just with different strings?
        if damage_value <= self.fortification
            enter_to_continue "#{self.name} blocks #{damage_value} damage!"
            self.fortification -= damage_value
        else
            puts "#{self.name} blocks #{self.fortification} damage!"
            unblocked_damage = damage_value - self.fortification
            self.fortification = 0
            enter_to_continue "#{self.name} takes #{unblocked_damage} damage!"
            lose_hp unblocked_damage
        end
    end

    def decide
        return false # every individual enemy class should have a decide method so this generic one *shouldn't* ever get called
    end
end

class ActionSpace < Player
    attr_accessor :name
    attr_accessor :description
    attr_accessor :phase
    attr_accessor :available
    attr_accessor :razed

    def execute 
        return false # similar to decide, shouldn't ever be called
    end

    def raze
        self.razed = true
        self.available = false
    end
end

class EnemyAction
    attr_accessor :name
    attr_accessor :intent_string

    def execute
        return false
    end
end

# ENEMY TYPES
class Barbarian < Enemy
    attr_accessor :attack_damage
    attr_accessor :rage 
    attr_accessor :player

    def initialize player
        self.max_hp = get_fuzzy_int 30, 5
        self.current_hp = max_hp
        self.name = "Barbarian"
        self.fortification = 0
        self.player = player
        self.attack_damage = 4
    end

    def decide
        self.next_action = EnemyAttack.new self, player, attack_damage
    end

    def take_damage damage_value # seems pretty awkward that this method is exactly the same as Player.take_damage just with different strings?
        if damage_value <= self.fortification
            enter_to_continue "#{self.name} blocks #{damage_value} damage!"
            self.fortification -= damage_value
        else
            puts "#{self.name} blocks #{self.fortification} damage!"
            unblocked_damage = damage_value - self.fortification
            self.fortification = 0
            puts "#{self.name} takes #{unblocked_damage}!"
            enter_to_continue "#{self.name} is enraged!  Attack damage increased!"
            self.attack_damage += 2
            lose_hp unblocked_damage
        end
    end
end

class Raider < Enemy
    attr_accessor :attack_damage
    attr_accessor :raze_target
    attr_accessor :actions
    attr_accessor :player

    def decide # this is not working for some reason
        rng = Random.new
        raze_target = player.action_spaces.sample
        self.attack_damage = get_fuzzy_int 6, 1
        raze = Raze.new self, player, raze_target
        attack = EnemyAttack.new self, player, attack_damage
        self.actions = [raze, attack]
        self.next_action = actions.sample
    end

    def initialize player
        self.player = player
        self.max_hp = get_fuzzy_int 25, 2
        self.current_hp = max_hp
        self.name = "Raider"
        self.fortification = 0
    end
end

# ENEMY ACTIONS
class EnemyAttack < EnemyAction
    attr_accessor :player
    attr_accessor :enemy
    attr_accessor :damage_value

    def initialize enemy, player, damage_value
        self.player = player
        self.enemy = enemy
        self.damage_value = damage_value
        self.name = "Attack"
        self.intent_string = "#{enemy.name} intends to attack for #{damage_value} damage"
    end

    def execute
        self.player.enter_to_continue "#{enemy.name} attacks you for #{damage_value} damage!"
        self.player.take_damage damage_value
    end
end

class Raze < EnemyAction
    attr_accessor :player
    attr_accessor :enemy
    attr_accessor :raze_target
    
    def initialize enemy, player, raze_target
        self.player = player
        self.enemy = enemy
        self.raze_target = raze_target
        self.name = "Raze"
        self.intent_string = "#{enemy.name} intends to raze #{raze_target.name}"
    end

    def execute
        player.enter_to_continue "#{enemy.name} razes #{self.raze_target.name}!"
        raze_target.raze
    end

end
# PLAYER ACTION SPACES
class Attack < ActionSpace
    attr_accessor :combat
    attr_accessor :damage_value

    def initialize
        self.damage_value = 6
        self.name = "Attack"
        self.description = "Deal 6 damage to one target."
        self.phase = 1
    end

    def execute
        if combat.living_enemies.length == 1
            target = combat.living_enemies[0]
        else
            combat.display_enemy_info
            target = select_from combat.living_enemies, "Choose an enemy to attack:"
        end
        enter_to_continue "You attack #{target.name} for #{damage_value} damage!"
        target.take_damage self.damage_value
    end
end

class Block < ActionSpace
    attr_accessor :player
    attr_accessor :fortification_value

    def initialize player
        self.player = player
        self.fortification_value = 5
        self.name = "Block"
        self.description = "Gain 5 Fortification."
        self.phase = 1
    end

    def execute
        enter_to_continue "You gain #{fortification_value} Fortification!"
        player.fortification += fortification_value
    end
end

class Gather < ActionSpace
    attr_accessor :player
    attr_accessor :material_gain

    def initialize player
        self.player = player
        self.material_gain = 3
        self.name = "Gather"
        self.description = "Gain 3 Materials."
        self.phase = 1
    end

    def execute
        enter_to_continue "You gain #{material_gain} Materials!"
        player.materials += 3
    end
end

class Forage < ActionSpace
    attr_accessor :player
    attr_accessor :food_gain

    def initialize player
        self.player = player
        self.food_gain = 3
        self.name = "Forage"
        self.description = "Gain 3 Food."
        self.phase = 1
    end

    def execute
        enter_to_continue "You gain #{food_gain} Food!"
        player.food += 3
    end
end

class Build < ActionSpace
    attr_accessor :player
    attr_accessor :material_cost

    def initialize player
        self.player = player
        self.material_cost = 10
        self.name = "Build"
        self.description = "Pay 10 Materials to build a house (can hold an additional Worker)."
        self.phase = 2
    end

    def execute
        if player.materials < 10 
            enter_to_continue "Not enough Materials!"
            player.free_workers += 1
            self.available = true
        elsif player.houses == 5
            enter_to_continue "Maximum house capacity reached!"
            player.free_workers += 1
            self.available = true
        else
            player.materials -= 10
            player.houses += 1
            enter_to_continue "House constructed!"
        end
    end
end

class Research < ActionSpace
    attr_accessor :player
    attr_accessor :material_cost

    def initialize player
        self.player = player
        self.material_cost = 10
        self.name = "Research"
        self.description = "Pay 10 Materials to unlock new Actions."
        self.phase = 1
    end

    def execute
        # should check to see if there are actually more actions available to research
        if player.materials < 10 # have a generic method for this bit, maybe?
            enter_to_continue "Not enough Materials!"
            player.free_workers += 1
            self.available = true
        else
            player.materials -= 10
            player.unlocked_phase += 1
            player.all_actions.each do |action|
                if action.phase == player.unlocked_phase
                    player.action_spaces << action
                    action.available = true
                    puts "#{action.name} unlocked!"
                end
            end
            enter_to_continue "Research completed!"
        end
    end
end

class Train < ActionSpace
    attr_accessor :player

    def initialize player
        self.player = player
        self.name = "Train"
        self.description = "Get an additional worker."
        self.phase = 2
    end

    def execute
        new_max = player.max_workers + 1
        if player.houses >= new_max
            enter_to_continue "You gained 1 worker!"
            player.max_workers += 1
        else
            enter_to_continue "Not enough room!"
            player.free_workers += 1
            self.available = true
        end
    end
end

class Scout < ActionSpace
    attr_accessor :player
    attr_accessor :combat
    attr_accessor :damage_value
    attr_accessor :fortification_value

    def initialize player
        self.player = player
        self.damage_value = 3
        self.fortification_value = 3
        self.name = "Scout"
        self.description = "Deal 3 damage to one target and gain 3 Fortification."
        self.phase = 2
    end

    def execute
        if combat.living_enemies.length == 1
            target = combat.living_enemies[0]
        else
            target = select_from combat.living_enemies, "Choose an enemy to attack:"
        end
        puts "You gain #{fortification_value} Fortification!"
        enter_to_continue "You attack #{target.name} for #{damage_value} damage!"
        player.fortification += fortification_value
        target.take_damage self.damage_value
    end
end