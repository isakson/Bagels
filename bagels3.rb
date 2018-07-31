require 'optparse'

$NUM_PLACES = 3
$SYMBOLS = "0123456789"
$RUNS = 10

$cmdline_options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    $cmdline_options[:verbose] = v
  end
end.parse!


## INTRO

def welcome
	puts "Welcome to Bagels!"
	puts "The object of the game is to successfully guess your opponent's 3-digit number in as few guesses as possible."
	puts "Following each guess, you will receieve partial information based on your guess."
	puts "1. 'Bagels' - none of the numbers guessed are in the number."
	puts "2. 'Pico' - one of the numbers guessed is in the number, but it is not in the correct location."
	puts "3. 'Fermi' - one of the numbers guessed is in the number at the correct location."
	puts "Picos will always be listed before Fermis."
	puts "Numbers may begin with a zero, but they must contain three distinct numbers."
	puts "The AI has chosen a number. You guess first!"
	
	#player_turn
	#initialize_ai_turn
	#end_game

end


## ERROR CHECKING SYSTEM


# Checks to ensure no repeats
def no_repeats(secret_array)
	numbers_used = []
	secret_array.each do |x|
		if numbers_used.include? x
			return false
		else
			numbers_used.push x
		end
	end
	return true
end


# Checks to ensure the input length is 3
def is_three(secret_array)
	if secret_array.length == $NUM_PLACES
		return true
	else
		return false
	end
end


# Checks to ensure the input is an integer 
def is_int(secret_array)
	secret_array.each do |x|
		if $SYMBOLS.include?(x) == false
			return false
		end
	end
	return true
end


# Implements all three checkers
def is_valid(secret_array)
	secret = secret_array.split('')
	if no_repeats(secret) && is_three(secret) && is_int(secret)
		return true
	else
		return false
	end
end


## NUMBER AND RESPONSE GENERATORS


# Generates a random, valid number
def ai_random
	random = rand(max=10**$NUM_PLACES - 1).to_s
	while true
		if is_valid(random)
			return random
		else
			random = rand(max=10**$NUM_PLACES - 1).to_s
		end
	end
end


## GAME MECHANICS


# Player guesses until finding AI's secret number
def player_turn
	secret = ai_random
	$player_turn_count = 0
	outcome = player_guess(secret)
	while outcome[0] != "C"
		puts outcome
		outcome = player_guess(secret)
	end
	# Is this what I want this to print?
	puts outcome
end


# Runs a single player guess
def player_guess(secret)
	$player_turn_count += 1
	puts "This is guess number #{$player_turn_count}."
	print "Guess: "
	guess = gets.chomp
	checker = false 
	while checker == false
		if is_valid(guess)
			checker == true
			return response(guess, secret)
		else
			puts "Invalid entry."
			print "Guess: "
			guess = gets.chomp
		end
	end
end
# AI guesses until finding player's secret number

class Guesser

	def initialize
		@statements = []
		@ai_turn_count = 0
		@options_list = []
		for i in 0...$NUM_PLACES
			options = {}
			@options_list.push(options)
			for i in 0...$SYMBOLS.length
				options[$SYMBOLS[i]] = true
			end
		end
		@target_response = ""
		for i in 0...$NUM_PLACES
			@target_response += "f"
		end
	end

	class Statement

		def initialize(clauses, how_many)
	    @clauses = clauses
	    @how_many = how_many
		end

		def satisfies?(guess)
			count = 0
			@clauses.each do |clause|
				if guess[clause.position] == clause.symbol
					count += 1
				end	
			end
			return count == @how_many 
		end

	end

	class Clause

		def initialize(symbol, position)
			@symbol = symbol
			@position = position
		end

		attr_reader :symbol, :position

	end

	# Evaluates guess, returns Pico-Fermi-Bagels string
	def compute_response(guess, secret)
	  guess_array = guess.split('')
	  secret_array = secret.split('')
	  pico_count = 0
	  fermi_count = 0
	  final_response = ""

	  for i in 0...$NUM_PLACES
	  	if guess_array[i] == secret_array[i]
	  		fermi_count += 1
	  	end
	  end

	  for i in 0...$NUM_PLACES
	  	if (secret_array.include? guess_array[i]) && (guess_array[i] != secret_array[i])
	  		pico_count += 1
	  	end
	  end

	  if fermi_count == 0 && pico_count == 0
	  	return "b"
	  end

	  if pico_count > 0
	  	pico_count.times do |x|
	  		final_response += "p"
	  	end
	  end

	  if fermi_count > 0
	  	fermi_count.times do |x|
	  		final_response += "f"
	  	end
	  end

	  return final_response  

	end

	def construct_guess(secret)
		already_guessed = {}
		checker = false
		#puts secret
		while checker == false
			@ai_turn_count += 1
			guess = ""
			while guess == ""
				for i in 0...$NUM_PLACES
					guess += "#{@options_list[i].keys.sample}"
				end
				if !is_valid(guess) || already_guessed.include?(guess)
					guess = ""
				else
					already_guessed[guess] = true
					@statements.each do |statement| 
						if !statement.satisfies?(guess)
							guess = ""
							break
						end
					end
				end
			end
			#puts guess

			response = compute_response(guess, secret)
			#puts "response is " + response

			learn(guess, response)

			if response == @target_response
				checker = true
			end
		end
		##CHANGED FROM PUTS TO RETURN
		return @ai_turn_count
	end

	def learn(guess, response)

		picos = 0
		fermis = 0
		response.each_char do |x|
			if x == "p"
				picos += 1
			elsif x == "f"
				fermis += 1
			end
		end
		
		pico_action = []	
		for i in 0...$NUM_PLACES
			for j in 0...$NUM_PLACES
				if i != j
					pico_action.push Clause.new(guess[i], j)
				end
			end
		end
		@statements.push Statement.new(pico_action, picos)


		fermi_action = []	
		for i in 0...$NUM_PLACES
			fermi_action.push Clause.new(guess[i], i)
		end
		@statements.push Statement.new(fermi_action, fermis)
	end
end





def initialize_ai_turn
	print "Now it's the AI's turn to guess. Enter your secret number here: "
	secret = gets.chomp
	checker = false
	
	while checker == false
		if is_valid(secret)
			checker = true
		else
			puts "Invalid entry. Enter your number here:"
			secret = gets.chomp
		end
	end
end



#Look at the average success
def average_guess_time
	average = 0
	$RUNS.times do |x|
		average += Guesser.new.construct_guess(ai_random)
	end
	puts average/$RUNS.to_f
end

#

# Determines and displays game results
# Change variables from global to local variables of welcome
def end_game
	$player_turn_count = 1
	if $player_turn_count == $ai_turn_count
		puts "You tie! Both players took #{$player_turn_count} guesses."
	elsif $player_turn_count > $ai_turn_count
		difference = $player_turn_count - $ai_turn_count
		puts "You lose! The AI made #{difference} fewer guesses."
	else
		difference = $ai_turn_count - $player_turn_count
		puts "You win! You made #{difference} fewer guesses than the AI."
	end
end

