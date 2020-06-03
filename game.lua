local game = {
  loaded = false,
  client_info = {}
}

--[[

game : table<dynamic>

game.state : table<dynamic>

game.state.players : table<player : {name : string, cards : table<string>}>

game.state.curr_player : number
game.state.draw_pile : table<string>
game.state.discard_pile : table<string>
game.state.direction : game.direction<enum> : {CLOCKWISE = 1, ANTI_CLOCKWISE = 2}
game.state.deck_suit : string
game.state.phase : string : {'running', 'over'}


game.client_info : table<dynamic>
game.client_info.player_id : number

]]

-- Enumerations

local direction = {CLOCKWISE = 1, ANTI_CLOCKWISE = 2}

-- Card getters

-- COMPLETE
local function get_card_from_draw_pile(draw_pile, discard_pile) -- return_type: string
  -- get top card from draw_pile
  -- when draw_pile is finished, reshuffle the cards from the discard pile into the draw_pile, and make the discard_pile empty. then return a new card from draw_pile

  if #draw_pile < 1 then -- draw_pile is empty! time to reshuffle the discard_pile and make it the draw_pile
    table.insert(draw_pile, table.remove(discard_pile, 1))
    while #discard_pile > 1 do -- we'll take every card except the top one i.e. last one
      table.insert(draw_pile, math.random(#draw_pile), table.remove(discard_pile, 1))
    end
  end
  return table.remove(draw_pile)
end

-- COMPLETE
local function get_top_card(discard_pile)
  -- the last card is the top one
  return discard_pile[#discard_pile]
end

-- COMPLETE
local function set_top_card(card, state)
  -- place card on state.discard_pile
  -- update state.deck_suit
  table.insert(state.discard_pile, card)
  state.deck_suit = card:sub(1, 1)
end

-- Initialization routines

-- COMPLETE, TESTED
local function build_deck() -- return_type : table
  -- return an UNO deck
  -- {'R0', 'R1', ... 'G0', 'G1', 'G2', ... 'W1', 'Wri1', ...}

  local deck = {}
  local suits = {'R', 'B', 'G', 'Y'}
  local ranks = {'1', '2', '3', '4', '5', '6', '7', '8', '9', 'D', 'S', 'R'}

  for _, suit in ipairs(suits) do
      table.insert(deck, suit .. '0')
    end
    
    for _, suit in ipairs(suits) do
      for _, rank in ipairs(ranks) do
        table.insert(deck, suit .. rank)
        table.insert(deck, suit .. rank)
      end
    end

    for i = 1, 4 do
      table.insert(deck, 'W1')
      table.insert(deck, 'W4')
    end

  return deck
end

-- COMPLETE
local function initialize_players_cards(players, draw_pile, discard_pile) -- (players : {1 : player, 2 : player, ...}) -> nil
  -- add 7 cards from draw_pile to all players
  for i, player in ipairs(players) do
    player.cards = {}
    for j = 1, 7 do                                                     
      local card = get_card_from_draw_pile(draw_pile, discard_pile)
      table.insert(player.cards, card)             
    end
    -- generate_valid_card_indices()
  end
end

-- COMPLETE
local function initialize_players_names(players, players_names)
  for i, player in ipairs(players) do
    player.name = players_names[i]
  end
end

-- COMPLETE
local function initialize_players(state, players_names)
  state.players = {}

  for i = 1, #players_names do
    state.players[i] = {}
    state.players[i].card_drawn = false
  end

  state.curr_player_id = 1
  state.curr_player = state.players[state.curr_player_id]

  initialize_players_names(state.players, players_names)
  initialize_players_cards(state.players, state.draw_pile, state.discard_pile)
end

-- COMPLETE
local function initialize_draw_pile(deck, state)
  state.draw_pile = {}
  -- insert items from deck randomly into state.draw_pile
  -- make sure deck's contents do not change
  table.insert(state.draw_pile, deck[1])
  for i = 2, #deck do
    table.insert(state.draw_pile, math.random(#state.draw_pile), deck[i])
  end
end

-- COMPLETE
local function initialize_discard_pile(state)
  state.discard_pile = {}
  table.insert(state.discard_pile, table.remove(state.draw_pile))
end

-- Card related functions

-- COMPLETE
local function get_suit(card) -- card - <string>
  -- 'R1' -> 'R'
  return card:sub(1,1)
end

-- COMPLETE
local function get_rank(card)
  -- 'R1' -> '1'
  return card:sub(2,2)
end

-- Rules enforcement

-- TODO 
local function change_direction(state)
    if state.direction == direction.CLOCKWISE then
        state.direction = direction.ANTI_CLOCKWISE
    else
        state.direction = direction.CLOCKWISE
    end
end

-- TODO
local function get_next_player_id(state)
  -- returns the next player on the basis of state.direction
  if state.direction == direction.CLOCKWISE then
    return state.curr_player_id == #state.players and 1 or state.curr_player_id + 1
  else
    return state.curr_player_id == 1 and #state.players or state.curr_player_id - 1
  end
end

local function get_next_player(state)
  return state.players[get_next_player_id(state)]
end

-- TODO
local function update_player(state)
  state.curr_player.card_drawn = false
  state.curr_player_id = get_next_player_id(state)
  state.curr_player = state.players[state.curr_player_id]
end

-- COMPLETE
local function is_card_playable(card, top_card, deck_suit)
    -- added to ensure only the the card matching the deck_suit is played when a W card is the top_card
    if get_suit(top_card) == "W" then
        return get_suit(card) == deck_suit or get_suit(card) == "W"
    else
        return get_suit(card) == deck_suit or get_rank(card) == get_rank(top_card) or get_suit(card) == 'W'
    end
end

-- TODO
-- valid_card_indices needs to be an empty table for each player so creating it inside generate_valid_card_indices
local function generate_valid_card_indices(player, top_card, deck_suit)
  -- gives valid moves for the curr_player
  player.valid_card_indices = {}
  for i = 1, #player.cards do
      if is_card_playable(player.cards[i],top_card, deck_suit) then
          table.insert(player.valid_card_indices, i)  
      end
  end
  player.selected_card_id = 1
end

-- TODO
apply_rules_first_time = coroutine.create(function (state)
  -- if it's draw 2, give state.curr_player 2 cards and skip his turn
  -- if it's a skip, skip state.curr_player's turn
  -- if it's a reverse, change direction. curr_player remains same
  -- if it's a wild 4, return the card to the bottom of the draw_pile
  -- if it's a wild, curr_player chooses the color
  local initial_top_card = get_top_card(state.discard_pile)

  if get_rank(initial_top_card) == "D" then
    for i=1, 2 do 
        table.insert(state.curr_player.cards, get_card_from_draw_pile(state.draw_pile, state.discard_pile))
    end
    update_player(state) 
    generate_valid_card_indices(state.curr_player, initial_top_card, state.deck_suit) 

  elseif get_rank(initial_top_card) == "S" then
    update_player(state)
    generate_valid_card_indices(state.curr_player, initial_top_card, state.deck_suit)
  
  elseif get_rank(initial_top_card) == "R" then
    change_direction(state)
    generate_valid_card_indices(state.curr_player, initial_top_card, state.deck_suit)
  
  elseif initial_top_card == "W4" then
    table.insert(state.draw_pile, 1, initial_top_card) --?
    set_top_card(get_card_from_draw_pile(state.draw_pile, state.discard_pile), state)
    generate_valid_card_indices(state.curr_player, initial_top_card, state.deck_suit)

  elseif initial_top_card == "W1" then
    -- halt operation, wait for user to select a suit, continue operation
    generate_valid_card_indices(state.curr_player, initial_top_card, state.deck_suit)
    game.state.phase = 'halted'
    state.deck_suit = coroutine.yield()
    game.state.phase = 'running'
    generate_valid_card_indices(state.curr_player, initial_top_card, state.deck_suit)
  end
end)


-- TODO
apply_rules = coroutine.create(function (state)
  -- if it's draw 2, give next player 2 cards and skip his turn
  -- if it's a skip, skip next player's turn
  -- if it's a reverse, change direction
  -- if it's a wild 4, attempt to give the next player 4 cards, allow him to challenge the current player, current player chooses the color
  -- if it's a wild, curr_player chooses the deck_suit
  while true do
    local top_card = get_top_card(state.discard_pile)
    if get_rank(top_card) == "D" then
      update_player(state)
      for i=1, 2 do 
          table.insert(state.curr_player.cards,get_card_from_draw_pile(state.draw_pile, state.discard_pile))
      end

    elseif get_rank(top_card) == "S" then
      update_player(state)
    
    elseif get_rank(top_card) == "R" then
      change_direction(state)
    
    elseif get_suit(top_card) == "W" then
      -- halt hehehe
      game.state.phase = 'halted'
      game.state.deck_suit = coroutine.yield()
      game.state.phase = 'running'
      if get_rank(top_card) == "4" then
          for i = 1, 4 do
              table.insert(get_next_player(state).cards, get_card_from_draw_pile(state.draw_pile, state.discard_pile))
          end
      end
      -- Colour Choosing -- Update deck_suit --
    end
    update_player(state) 
    generate_valid_card_indices(state.curr_player, top_card, state.deck_suit)
    coroutine.yield()
  end
end)

local function check_game_termination(state)
    if #state.curr_player.cards == 0 then
        -- terminating game if player has no cards --
        state.phase = "over"
    end
end

-- Points calculation

-- COMPLETE
local function get_card_value(card)
  local value = 0
  if card:sub(1,1) == "W" then value = 50
  elseif string.match(card:sub(2,2), '[DSR]') then value = 20
  elseif string.match(card:sub(2,2), '[0-9]') then value = tonumber(card:sub(2,2))
  end
end

-- COMPLETE
local function get_player_cards_value(player)
  local value = 0
  for i, card in ipairs(player.cards) do
    value = value + get_card_value(card)
  end
  return value
end

-- COMPLETE
local function get_points_for_winner(winner_id, players)
  local value = 0
  for i, player in ipairs(players) do
    if i ~= winner_id then
      value = value + get_player_cards_value(player)
    end
  end
  return value
end

-- Drawing utilities

-- COMPLETE
local function table_string(t) -- return_type : string
  -- return a string representation of table 't'
  -- t may contain tables, which may contain tables and so on
  local s = '{'
  for k, item in t do
      if type(item) == 'table' then
          s = s .. table_string(item)
      else
          s = s .. string.format('%s', item)
      end
      if next(t, k) then
          s = s .. ', '
      end
  end
  s = s .. '}'
  return s
end

-- COMPLETE, TESTED
local function table_string_nr(t) -- return_type : string
  -- return a string representation of table 't'
  -- t doesn't contain tables
  -- performance friendly alternative to table_string(t). Can be called multiple times for example in update(dt) or draw()
  return '{' .. table.concat(t, ', ') .. '}'

end

local function table_string_nr_hidden(t) -- return_type : string
  -- return a string representation of table 't'
  -- t doesn't contain tables
  -- performance friendly alternative to table_string(t). Can be called multiple times for example in update(dt) or draw()
  s = '{'
  for i, _ in ipairs(t) do
    s = s .. (next(t, i) ~= nil and 'X, ' or 'X')
  end
  s = s ..'}'
  return s
  -- return '{' .. table.concat(t, ', ') .. '}'

end

-- Primary drawing functions (primitive implementation, just for testing and debugging) (Later on, these will be superseded by actual graphical drawing routines)

-- COMPLETE, TESTED
local function show_player(player, is_current, x, y, window_dimensions)
  local s
  if is_current then
    if player.name ~= game.client_info.player_name then
      s = string.format('*%s\nSelection: %s\n%s\n', player.name, player.cards[player.valid_card_indices[player.selected_card_id]], table_string_nr_hidden(player.cards))
    else
      s = string.format('*%s\nSelection: %s\n%s\n', player.name, player.cards[player.valid_card_indices[player.selected_card_id]], table_string_nr(player.cards))
    end
  else
    if player.name ~= game.client_info.player_name then
      s = string.format('%s\n%s', player.name, table_string_nr_hidden(player.cards))
    else
      s = string.format('%s\n%s', player.name, table_string_nr(player.cards))
    end
  end
  love.graphics.printf(s, x - 150, y, 300, 'center')
end

-- COMPLETE, TESTED
local function show_players(state, window_dimensions)
  local dims = window_dimensions
  local a, b = 1 / (dims.x * 2.5), dims.y / 3 -- this can be moved into game:load(...) so that we don't need to do useless calculations 60 times a second
  -- players placed in a curve : a(x-window_dimensions.x)(x) + b
  local n = #state.players
  local separation = dims.x / (n + 1)
  for i, player in ipairs(state.players) do
    local x = i * separation
    show_player(player, i == state.curr_player_id, x, a * (x - dims.x) * (x) + b, window_dimensions)
  end
end

-- COMPLETE
local function show_draw_pile(draw_pile, window_dimensions)
  -- love.graphics.printf has word_wrap and alignment as well!
  -- Here, word_wrap has been used
  love.graphics.printf(string.format('Draw Pile: %s', table_string_nr(draw_pile)), window_dimensions.x / 2, window_dimensions.y / 2, window_dimensions.x / 2 - 5)
end

-- COMPLETE
local function show_discard_pile(discard_pile, window_dimensions)
  -- love.graphics.printf(string.format('Discard Pile: %s', table_string_nr(discard_pile)), window_dimensions.x / 2 + 5, window_dimensions.y / 2, window_dimensions.x / 3 - 5)
  love.graphics.printf(string.format('Discard Pile: %s', discard_pile[#discard_pile]), window_dimensions.x / 2 - 100, window_dimensions.y / 2, 200, 'center')
end

local function show_deck_suit(deck_suit, window_dimensions)
    love.graphics.printf(string.format('Deck Suit: %s', deck_suit), window_dimensions.x / 2 - 100, window_dimensions.y / 2 - 20, 200, 'center')
end

-- Selection shifting

local function move_selection_left(curr_player)
  curr_player.selected_card_id = curr_player.selected_card_id == 1 and #curr_player.valid_card_indices or curr_player.selected_card_id - 1
end

local function move_selection_right(curr_player)
  curr_player.selected_card_id = (curr_player.selected_card_id % #curr_player.valid_card_indices) + 1
end

-- Love2D integration functions

-- PARTIALLY COMPLETE
function game.load(game, players_names)
  game.window_dimensions = {x = love.graphics.getWidth(), y = love.graphics.getHeight()}
  -- put this function in love.load()

  player_names = player_names or {'A', 'B', 'C', 'D'} -- if nothing is passed, we'll assume these 4 random names
  
  game.state = {}
  game.state.direction = direction.CLOCKWISE
  game.state.phase = 'running'
  -- Cannot initialize players without having a draw_pile first!
  local deck = build_deck()
  initialize_draw_pile(deck, game.state)
  -- Now that we have a draw pile, we'll initialize the players
  initialize_players(game.state, players_names)
  -- Finally, we add 1 card to the discard_pile
  initialize_discard_pile(game.state)
  -- At this point, we have some players with random cards; a shuffled draw_pile; a discard_pile with a card on top
  -- print(table_string_nr(game.state.draw_pile))
  -- Other initialization tasks

  game.state.deck_suit = get_suit(game.state.discard_pile[#game.state.discard_pile])

  coroutine.resume(apply_rules_first_time, game.state)
  game.loaded = true
end

-- TODO
function game.update(game, dt)
  -- put this function in love.update(dt)
end

-- PARTIALLY COMPLETE
function game.draw(game)
  -- put this function in love.draw()
  show_players(game.state, game.window_dimensions)
  -- show_draw_pile(game.state.draw_pile, game.window_dimensions)
  show_discard_pile(game.state.discard_pile, game.window_dimensions)
  show_deck_suit(game.state.deck_suit,game.window_dimensions)
  if game.state.phase == 'over' then
    -- show final score
  end
end

function game.keypressed(game, key)
  local curr_player = game.state.curr_player
  if game.state.phase == 'running' then
    if key == 'left' then -- move card selection left for current player's valid cards
      move_selection_left(curr_player)

    elseif key == 'right' then -- move card selection right for current player's valid cards
      move_selection_right(curr_player)
      
    elseif key == 'space' and #game.state.curr_player.valid_card_indices ~= 0 then -- play the current selected card of current player and update the player (?) (this already happens in apply rules yes?) Yes ok
      -- add current selected card to the top of the discard_pile
      set_top_card(table.remove(curr_player.cards, curr_player.valid_card_indices[curr_player.selected_card_id]), game.state)
      check_game_termination(game.state)
      if game.state.phase ~= 'over' then
        coroutine.resume(apply_rules, game.state)
      end
    elseif not curr_player.card_drawn and key == 'p' then
      -- pick a card from draw_pile
      local card = get_card_from_draw_pile(game.state.draw_pile, game.state.discard_pile)
      table.insert(curr_player.cards, card)
      game.state.curr_player.card_drawn = true
      for i in pairs(game.state.curr_player.valid_card_indices) do
        game.state.curr_player.valid_card_indices[i] = nil
      end
      if is_card_playable(card, get_top_card(game.state.discard_pile), game.state.deck_suit) then 
        table.insert(curr_player.valid_card_indices, #curr_player.cards)
      end
    --   generate_valid_card_indices(curr_player, get_top_card(game.state.discard_pile), game.state.deck_suit)
      if #game.state.curr_player.valid_card_indices == 0 then
        update_player(game.state)
        generate_valid_card_indices(game.state.curr_player, get_top_card(game.state.discard_pile), game.state.deck_suit)
      end
      
    end
  elseif game.state.phase == 'halted' then
       if key == 'r' or key == 'g' or key == 'b' or key == 'y' then
            if coroutine.status(apply_rules_first_time) == 'suspended' then
                coroutine.resume(apply_rules_first_time, key:upper())
              elseif coroutine.status(apply_rules) == 'suspended' then
                coroutine.resume(apply_rules, key:upper())
            end
        end
  end
end

return game

-- To be fixed --

--D 1.The deck_suit does not get updated after colour selection.
--D 2.The valid_card selection has a problem when 'W' is the top_card, 
-- as we even match the rank for selecting a valid card, cards with rank 1/4 irrespective of the deck suit get selected
--D 3.No end game happens. (Nothing happens when a player's cards run out.)
--D 4. When selection is nil, player can still play some card when space is pressed. 
      -- added a condition in game.keypressed for space, #game.state.curr_player.valid_card_indices ~= 0 -- Works


-- More features --

--D 5. if you pick a card, you cannot play any card other than that card
-- so even if you had other valid cards, after picking, they will not be counted as valid playable cards
-- 6. a 'pass' button to pass one's turn
-- 7. "UNO" option and its penalty