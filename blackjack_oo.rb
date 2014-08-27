
require 'rubygems'
require 'pry'

class Card
  attr_accessor :suit, :value

  def initialize(s, v)
    @suit = s
    @value = v
  end

  def pretty_output
    "The #{value} of #{find_suit}."   # use getter 'value' and not inst. variable "@value"
  end                                 # removed 'puts' in line 14 to clean-up output (get rid of object identifier)

  def to_s
    pretty_output
  end

  def find_suit
    case suit
    when 'H' then 'Hearts'
    when 'D' then 'Diamonds'
    when 'S' then 'Spades'
    when 'C' then 'Clubs'
    end
  end
end

class Deck
  attr_accessor :cards
  def initialize
    @cards = []    # since a deck is an array of card objects!  not just [] of []'s like in procedural'
    ['H', 'D', 'S', 'C'].each do |suit|     # combining suit and value into @cards
      ['2','3','4','5','6','7','8','9','10', 'J', 'Q', 'K', 'A'].each do |value|
        @cards << Card.new(suit, value)   # notice that @ cards is plural
      end
    end         # should have array of card ojects in the instance variable  @cards
    shuffle!    # call shuffle method from within .new method!
  end

  def shuffle!
    @cards.shuffle!
  end

  def deal_one
    cards.pop   # instance method call (getter) to @cards (array of card objects), then popping one off the end
  end

  def size
    cards.size
  end
end

module Hand     # 'has a' relationship (composition) for shared behavior between player and dealer objects
  def show_hand
    puts "===== #{name}'s Hand ====="   # name is the getter of the @name (name instance variable)
    cards.each do |card|                # iterate through each card from cards (getter method)
      puts "=> #{card}"            # prints each card element using def pretty_output (from the to_s method call implicit in interpolation)
    end
    puts "=> Total: #{total}"     # calling total method call (.total) in show_hand
    puts         
  end

  def total                   # copied calculate_hands method from procedural blackjack game
    value = cards.map {|card| card.value} # create value local variable and calling .value method on each card (getter method) in the cards array of objects.
                                          # will create new array (.map) of only value
    total = 0                   # set hand to 0
    value.each do |val|         # cycle through each value and determine value to hand
      if val == "A"           # start with most restrictive case
        total += 11             # increment by 11 (high value for ace)
      else                      # all non-integer values remaining after taking aces out
        total += (val.to_i == 0 ? 10 : val.to_i)    # true evaluates to 10 - face cards are all worth 10.  False evaluates to value.to_i. increment total by value of card, i.e 2-10
      end
    end

    # handle dual nature of aces
    value.select{|val| val == "A"}.count.times do   # counts number of times the aces are in the hand and creates loop equal to that number
      break if total <= Blackjack::BLACKJACK_AMOUNT    # breaks loop so Ace = 11 (does not subtract 10 in next line)
      total -= 10             # subtracts 10 each do/end loop (assigned from .times method).  Aces = 1!
    end
    total                     # returns total
  end

  def add_card(new_card)      # to add card to Hand and not rely on shovel (<<) operator (since module - both player and dealer can acess). 
    cards << new_card
  end

  def is_busted?              # returns boolean (true/false)
    total > Blackjack::BLACKJACK_AMOUNT  # naming for Blackjack class and BLACKJACK_AMOUNT constant
  end
end

class Player   # look to .new method call to determine if we need a parameter
  include Hand  # include the Hand module
  attr_accessor :name, :cards  # for getter and setter.  If don't want to change instance variable after it's initialized (just get), use attr_reader
  
  def initialize(n)
    @name = n
    @cards = []        # Initialize cards array to empty [].  During course of game we get gards!  Player needs to keep track of it's cards (primary state to track) Most Important
  end                  # create player, then when game starts, it deals cards to player.  Need way to add card to cards. Therefore need getter and setter methods

  def show_flop
    show_hand
  end
  
end

class Dealer
  include Hand
  attr_accessor :name, :cards  # no need to pass in dealer name param

  def initialize
    @name = "Dealer"  # assign dealer object name to "Dealer"
    @cards = []
  end

  def show_flop
    puts "===== Dealer's Hand ====="
    puts "=> The first card is hidden."
    puts "=> The second card is: #{cards[1]}"
  end
end

class Blackjack                 # 1. want to call with game = Blackjack.new, game.start
  BLACKJACK_AMOUNT = 21
  DEALER_HIT_MIN = 17

  attr_accessor :deck, :player, :dealer

  def initialize                # to create new game object (from .new)
    @deck = Deck.new
    @player = Player.new("Player1")
    @dealer = Dealer.new         # no param needed since only 1 dealer
   end

   def set_player_name
    puts "=> What is your name?"
    player.name = gets.chomp    # player.name is a setter for name (@name), in class Player (player is getter)
   end

   def deal_cards
    player.add_card(deck.deal_one)
    dealer.add_card(deck.deal_one)
    player.add_card(deck.deal_one)
    dealer.add_card(deck.deal_one)
  end

  def show_flop
    player.show_flop
    dealer.show_flop
  end

  def blackjack_or_bust?(player_or_dealer)
    if player_or_dealer.total == BLACKJACK_AMOUNT  # no matter which class (Player or Dealer), both inherit .total from Hand module!
      if player_or_dealer.is_a?(Dealer)     # use .is_a to determine which oblect class we are dealing with!
        puts "Sorry, Dealer hit blackjack. #{player.name} loses!" # watch tenses - esp if use multiple players
      else
        puts "#{player.name} hit blackjack!"
      end
      play_again?              # put in play_again? or (exit) to exit program here!
    elsif player_or_dealer.is_busted?
      if player_or_dealer.is_a?(Dealer)
        puts "Congratulations! Dealer busted - #{player.name} wins!"
      else
        puts "#{player.name} busted.  Better luck next time!"
      end
      play_again?              # put in play_again? or (exit) to exit program here! 
    end
  end

  def player_turn
    puts
    puts "#{player.name}'s turn."

    blackjack_or_bust?(player)      # use method from 178! instead of create helper method hit_blackjack?(player) to check for both player and dealer
    
    while !player.is_busted?
      puts "=> Do you wish to 1) hit or 2) stay?"
      response = gets.chomp

      if !['1','2'].include?(response)  # => if !['1', '2'].include?(hit_or_stay)
        puts "=> Try again: enter a 1 to hit or 2 to stay."
        puts "-------------"
        next                                        # move to next block in while loop
      end

      if response == '2'
        puts "#{player.name} chose to stay at #{player.total}."
        break
      end

    # hit
    new_card = deck.deal_one
    puts "Dealing card to #{player.name}: #{new_card}"
    player.add_card(new_card)   # adds new card to player
    player.total                # implicitly delegates .total (Hand module) to player
    puts "#{player.name}'s total is now: #{player.total}"

    blackjack_or_bust?(player)  # name (and must create) new helper method (line 155 is a subset of line 178's helper)
  end                           # end of player turn to hit
end

  def dealer_turn
    puts "Dealer's turn."

    blackjack_or_bust?(dealer)
    while dealer.total < DEALER_HIT_MIN    # logic for dealer to hit
      new_card = deck.deal_one
      puts "Dealing card to Dealer: #{new_card}"
      dealer.add_card(new_card)
      puts "Dealer total is now: #{dealer.total}"

      blackjack_or_bust?(dealer) # why is this here? iterative loop
    end
    puts "Dealer stays at #{dealer.total}."        # dealer has more 18 - 20 and is staying
 end

  def who_won?                   # no need to pass in parameters (will need to if want to consider players who didnt bust )
    if player.total > dealer.total
      puts "Congratulations #{player.name} - you win!!!"
    elsif player.total < dealer.total
      puts "Sorry, #{player.name} loses - maybe next time!"
    else
      puts "It's a push!  The Dealer and #{player.name} both have #{player.total}."   
    end
    play_again?                      # put in play_again? or (exit) to exit program here! 
  end

  def play_again?
    puts "Do you want to play again? 1) yes 2) no, exit."
      if gets.chomp == '1'
        puts "Starting new game..."
        puts ""
        deck = Deck.new       # to clear the deck (re-initialise it to a new deck) because we decrease the size of the deck when we deal out cards        player.cards = []
        player.cards = []     # clear the cards held by player (and dealer) setting to empty arrays
        dealer.cards = []
        start
      else
        puts "Goodbye!"
        exit
      end
  end

  def start                     # 1. list method calls to actions/behaviors needed in certain order.  Then create them 
    set_player_name
    deal_cards
    show_flop
    player_turn
    dealer_turn
    who_won?                  # if pass in params here, make sure I add them to the who_won? method
  end
end


game = Blackjack.new
game.start


# deck = Deck.new
# player = Player.new("Justin")   # want to initiate player object with state (name) of Justin
# player.add_card(deck.deal_one)
# player.add_card(deck.deal_one)
# player.add_card(deck.deal_one)
# player.add_card(deck.deal_one)
# player.show_hand                # want player object to display cards that the player has
# player.total                    # want player object to calculate total hand 

# dealer = Dealer.new             # no name state needed to initialize new dealer object
# dealer.add_card(deck.deal_one)
# dealer.add_card(deck.deal_one)
# dealer.add_card(deck.deal_one)
# dealer.add_card(deck.deal_one)
# dealer.show_hand                # a lot of overlap between player and dealer
# dealer.total                    #

