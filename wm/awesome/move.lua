Move = {}
function Move.up (c, delta)
    c.y = c.y - delta
end
function Move.down (c, delta)
    c.y = c.y + delta
end
function Move.left (c, delta)
    c.x = c.x - delta
end
function Move.right (c, delta)
    c.x = c.x + delta
end

-- Swipe to edge
function Move.to_edge (c, destination, indent)
    local indent = indent or 30
    local screen = c.screen
    local max_x = screen.geometry.width - c.width
    local max_y = screen.geometry.height - c.height
    
    local actions = {
        ["left"] = function (c) 
                        c.x = 0 + indent
                    end,
        ["top"] = function (c)
                        c.y = 0 + indent
                    end,
        ["right"] = function (c) 
                        c.x = max_x - indent
                    end,
        ["bottom"] = function (c)
                        c.y = max_y - indent
                    end,
    }

    actions[destination](c)
end

return Move
