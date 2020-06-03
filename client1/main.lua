-- Client
local enet = require("enet")
local game = require("game")

local client_name = 'Player_1'

local function state_construct(state_str) -- return_type : table
    -- 'R4 G1 W4' -> {'R4', 'G1', 'W4'}
    local t = {}
    for card in string.gmatch(state_str, "%S+") do
        table.insert(t, card)
    end
    return t
end

local function transmit_keystroke(key_str, server)
	server:send(key_str)
end

function love.load()
    love.window.setTitle(client_name)
    host = enet.host_create() -- no ip means that it will connect to someone, instead of others connecting to it.
    messages = {}
    server = host:connect("127.0.0.1:2456", nil, 1234)
end

function parse_names(str)
    local names = {}
    local start, finish = 0, string.find(str, " ", 0)
    while #names < 3 do
        names[#names+1] = string.sub(str, start, finish-1)
        start = finish + 1
        finish = string.find(str, " ", start)
    end
    return names
end

function love.update(dt)
    event = host:service(100)
    if event then
        if event.type == "connect" then
            event.peer:send(client_name)
        elseif event.type == "receive" then
            if not game.loaded then
                local names = parse_names(event.data)
                for id, name in ipairs(names) do
                    if name == client_name then
                        game.client_info.player_id = id
                        game.client_info.player_name = name
                    end
                end
                game:load(names)
            else -- table.insert(messages, string.format("Got message: %s %s", event.data, event.peer))
                game:keypressed(event.data)
            end
        end
    end
    if game.loaded then
        game:update(dt)
    end
end

function love.draw()
    love.graphics.printf(table.concat(messages, '\n'), 200, 100, 300)
    if game.loaded then
        game:draw()
    end
end

function love.keypressed(key)
    if game.loaded and (game.client_info.player_id == game.state.curr_player_id) then
        transmit_keystroke(key, server)
    end
end
