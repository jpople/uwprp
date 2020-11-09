require './newclasses.rb'

game = Game.new
player = Player.new

puts "Welcome to Untitled Worker Placement Roguelite Project's pre-Alpha version!"
puts "You can type 'quit' at any time to quit the game.  If it's your first time playing, you should read help.txt in the game directory."
puts
game.enter_to_continue "Although, like, I find it hard to imagine that you'd reach this screen without knowing me in real life, so you can also just hit me up and ask if you have questions."

while game.current_floor < 6 do
    enemy_pool = [Raider.new(player), Raider.new(player), Barbarian.new(player), Barbarian.new(player)]
    difficulty = (current_floor / 2.0).ceil
    enemies = enemy_pool.sample difficulty
    combat = Combat.new player, enemies
    combat.run
end
game.win_screen