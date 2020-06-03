-- Server
local enet = require("enet")

local function server_side_input_handler(event)
    --[[
        1.
        2. 
        3.
        4. some way to 'pass'
        5. some way to 'pick up card'
        6.
    ]]

end

local function transmit_message(message, client) -- return_type : nil
	client:send(message)
end

local function table_to_str(t) -- return_type : string
    -- {'R4', 'G3', 'W1'} -> 'R4 G3 W1'
    local str = table.concat(t, ' ')
    return str .. ' '
end

function love.load()
    love.window.setTitle('Server')
    host = enet.host_create('127.0.0.1:2456')

    players = {}

    messages = {}
end

function love.update(dt)
    local event = host:service(100)
    if event then
        if event.type == 'connect' then
            messages[#messages+1] = string.format('%s has connected!', event.peer)

        elseif event.type == "receive" then -- we have received stuff from some client
            if #players < 3 then
                players[#players+1] = event.data
                if #players == 3 then
                    -- game:load(players)
                    -- messages[#messages+1] = 'Game loaded!'
                    host:broadcast(table_to_str(players))
                end
            else
                -- normal things
                messages[#messages+1] = string.format(event.data)
                host:broadcast(event.data)
            end
        end
   end
end

function love.draw()
    love.graphics.printf(table.concat(messages, '\n'), 200, 100, 300)
end










