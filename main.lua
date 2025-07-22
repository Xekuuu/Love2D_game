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

    terrain = {
        x = 0,
        y = 0,
        size = 1000
    }

    cam = Camera(player.x, player.y)

    
    hookActive = false
    hookSpeed = 500
    hookTargetX = 0
    hookTargetY = 0
end

function love.update(dt)
    local dx, dy = 0, 0

    if love.keyboard.isDown("w") then dy = dy - 1 end
    if love.keyboard.isDown("s") then dy = dy + 1 end
    if love.keyboard.isDown("a") then dx = dx - 1 end
    if love.keyboard.isDown("d") then dx = dx + 1 end

    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx*dx + dy*dy)
        dx = dx / len
        dy = dy / len
    end

    
    if not hookActive then
        player.x = player.x + dx * player.speed * dt
        player.y = player.y + dy * player.speed * dt
    end

    -- grappling hook 
    if love.keyboard.isDown("space") and not hookActive then
        flag = true 
        hookTargetX = player.x - 170
        hookTargetY = player.y - 150
        if flag==true then
            NonUpdateingY=hookTargetY
            NonUpdateingX=player.x+170
            flag=false
        end
        hookActive = true
    end

    if hookActive then
        local hx = hookTargetX - player.x
        local hy = hookTargetY - player.y
        local distance = math.sqrt(hx*hx + hy*hy)

        if distance > 2 then
            local nx = hx / distance
            local ny = hy / distance
            player.x = player.x + nx * hookSpeed * dt
            player.y = player.y + ny * hookSpeed * dt
        else
            player.x = hookTargetX
            player.y = hookTargetY
            hookActive = false
        end
    end

    
    player.x = math.max(terrain.x, math.min(player.x, terrain.x + terrain.size - player.size))
    player.y = math.max(terrain.y, math.min(player.y, terrain.y + terrain.size - player.size))

    cam:lockPosition(player.x + player.size / 2, player.y + player.size / 2)

    
    if not itemz.collected and
        player.x < itemz.x + itemz.size and
        player.x + player.size > itemz.x and
        player.y < itemz.y + itemz.size and
        player.y + player.size > itemz.y then

        player.speed = player.speed + itemz.value
        itemz.collected = true
    end
end

function love.draw()
    cam:attach()

    
    love.graphics.setColor(0, 255, 0)
    love.graphics.rectangle("fill", terrain.x, terrain.y, terrain.size, terrain.size)
    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle("line", terrain.x, terrain.y, terrain.size, terrain.size)

    
    --  if hookActive then
    --      love.graphics.setColor(255, 255, 0)
    --      love.graphics.line(
    --         player.x + player.size / 2,
    --         player.y + player.size / 2,
    --         player.x - 170,
    --         player.y - 150
    --      )
    --      test=false
    -- end
    love.graphics.setColor(255, 255, 0)
    if hookActive then
        love.graphics.line(
            player.x + player.size / 2, -- od igraco x 
            player.y + player.size / 2, -- od igraco y 
            NonUpdateingX-50, 
            NonUpdateingY
         )
    end
    
    

    
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)

    
    if not itemz.collected then
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", itemz.x, itemz.y, itemz.size, itemz.size)
    end

    cam:detach()
end
