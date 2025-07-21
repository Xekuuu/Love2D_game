local Camera = require "camera"
local cam



function love.load()
    player = {
        x = 100,
        y = 100,
        speed = 300,
        size = 32
    }
    itemz = {
        x = 200,
        y = 200,
        value = 500,
        size = 16,
        collected = false
    }
    cam = Camera(player.x, player.y)
    terrain = {
        x = 0,
        y = 0,
        size = 1000
    }
end

function love.update(dt)
    local dx, dy = 0, 0

    if love.keyboard.isDown("w") then dy = dy - 1 end
    if love.keyboard.isDown("s") then dy = dy + 1 end
    if love.keyboard.isDown("a") then dx = dx - 1 end
    if love.keyboard.isDown("d") then dx = dx + 1 end


    -- diag
    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx*dx + dy*dy)
        dx = dx / len
        dy = dy / len
    end

    player.x = player.x + dx * player.speed * dt
    player.y = player.y + dy * player.speed * dt

    cam:lockPosition(player.x + player.size/2, player.y + player.size/2)

    if not itemz.collected and
        player.x < itemz.x + itemz.size and
        player.x + player.size > itemz.x and
        player.y < itemz.y + itemz.size and
        player.y + player.size > itemz.y then

        player.speed = player.speed + itemz.value
        itemz.collected = true
    end
    player.x = math.max(terrain.x, math.min(player.x, terrain.x + terrain.size - player.size))
    player.y = math.max(terrain.y, math.min(player.y, terrain.y + terrain.size - player.size))
end

function love.draw()
    cam:attach()

    -- graphics
    love.graphics.setColor(0,255,0)
    love.graphics.rectangle("fill", terrain.x, terrain.y, terrain.size, terrain.size)
    love.graphics.setColor(255,255,255)
    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)
    love.graphics.setColor(255,0,0)
    love.graphics.rectangle("line", terrain.x, terrain.y, terrain.size, terrain.size)
    love.graphics.setColor(0,0,0)

    

    if not itemz.collected then
        love.graphics.rectangle("line", itemz.x, itemz.y, itemz.size, itemz.size)
    end
    cam:detach()
    -- ui dolu
end
