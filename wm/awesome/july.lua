local awful = require("awful")

local capi = {
    screen = screen,
    client = client
}

july = {}
july.tasklist = {}

local function reversed(table) 
    local i = 1
    local j = #table

    while i < j do
        table[i], table[j] = table[j], table[i]
        i = i + 1
        j = j - 1
    end

    return table
end

function log(text)
    local file = io.open("/home/julian/log.txt", "a")
    io.output(file)
    io.write(text)
    io.close(file)
end

function july.spawn_once(cmd, storage, rules)
    if storage[cmd] then
        -- log("Cmd in storage\n")
        local pid = storage[cmd]
        for _, c in ipairs(client.get()) do
            if c["pid"] == pid then
                -- log("Pid in storage\n")
                c:jump_to()
                return
            end
        end
    end
    -- log("Spawning window\n")
    local pid = awful.spawn(cmd, rules)
    storage[cmd] = pid
end

function july.summon(cmd, storage, rules)
    if storage[cmd] then
        local pid = storage[cmd]
        for _, c in ipairs(client.get()) do
            if c["pid"] == pid then
                local tag = client.focus and client.focus.first_tag or
                            awful.screen.focused().selected_tag
                -- if c.first_tag == tag then
                    -- c.ontop = not c.ontop
                    -- for _, c_ in ipairs(tag:clients()) do
                        -- if not (c == c_) then
                            -- c_:jump_to()
                        -- end
                    -- end
                -- else
                c:move_to_tag(tag)
                c:jump_to()
                -- end
                return
            end
        end
    end
    local pid = awful.spawn(cmd, rules)
    storage[cmd] = pid
end


function july.tasklist.source_all()
    all_clients = capi.client.get()
    return reversed(all_clients)
end


return july
