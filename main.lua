local Camera = require "camera"
local cam

function love.load()
    player = {
        x = 100,
        y = 100,
        speed = 300,
        size = 32,
        hp = 100,
        isdead = false  
    }

    itemz = {
        x = 200,
        y = 200,
        value = 500,
        size = 16,
        collected = false
    }

    itemzD = {
        x = 400,
        y = 400,
        value = 500,
        size = 16,
        collected = false
    }

    terrain = {
        x = 0,
        y = 0,
        size = 1250
    }

    cam = Camera(player.x, player.y)

    
    hookActive = false
    hookSpeed = player.speed*2.5
    hookTargetX = 0
    hookTargetY = 0
    hookCooldown = 0
    hookCooldownTime = 0.8 -- cd  
    
    
end

function love.update(dt)
    
    if hookCooldown > 0 then
        hookCooldown = hookCooldown - dt
    end

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

    
    if love.keyboard.isDown("r") then
        player.x = 100
        player.y = 100
        player.speed = 300
        player.hp = 100  
        itemz.collected = false
        itemzD.collected = false  
        hookActive = false
        hookTargetX = 0
        hookTargetY = 0
        hookCooldown = 0 
        player.isdead = false  
    end

    
    if love.keyboard.isDown("space") and not hookActive and hookCooldown <= 0 then
        flag = true 
        
        -- top left space + a OR w + a + space
        if love.keyboard.isDown("a") and (love.keyboard.isDown("w") or not love.keyboard.isDown("s")) then
            hookTargetX = player.x - 170
            hookTargetY = player.y - 150
        
        -- top right: space + d OR w + d + space
        elseif love.keyboard.isDown("d") and (love.keyboard.isDown("w") or not love.keyboard.isDown("s")) then
            hookTargetX = player.x + 170
            hookTargetY = player.y - 150
        
        -- bottom left: s + a + space
        elseif love.keyboard.isDown("s") and love.keyboard.isDown("a") then
            hookTargetX = player.x - 170
            hookTargetY = player.y + 150
        
        -- bottom right: s + d + space
        elseif love.keyboard.isDown("s") and love.keyboard.isDown("d") then
            hookTargetX = player.x + 170
            hookTargetY = player.y + 150
        
        -- down: space + s 
        elseif love.keyboard.isDown("s") and not love.keyboard.isDown("a") and not love.keyboard.isDown("d") then
            hookTargetX = player.x
            hookTargetY = player.y + 200
        
        -- default case (space) 
        else
            hookTargetX = player.x 
            hookTargetY = player.y - 200
        end
        
        if flag==true then
            NonUpdateingY=hookTargetY
            NonUpdateingX=player.x+170
            flag=false
        end
        hookActive = true
        hookCooldown = hookCooldownTime  
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

    if not itemzD.collected and
        player.x < itemzD.x + itemzD.size and
        player.x + player.size > itemzD.x and
        player.y < itemzD.y + itemzD.size and
        player.y + player.size > itemzD.y then

        player.hp = player.hp - itemzD.value  
        itemzD.collected = true
    end

    
    if player.hp <= 0 then
        player.isdead = true
        player.speed=0
    end
end


function love.draw()
    cam:attach()

    
    
    love.graphics.setColor(0, 255, 0)
    love.graphics.rectangle("fill", terrain.x, terrain.y, terrain.size, terrain.size)
    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle("line", terrain.x, terrain.y, terrain.size, terrain.size)

    if player.isdead == true then
        love.graphics.setColor(255, 0, 0)  
        love.graphics.print("DEAD", player.x, player.y-50)
    end

    
    love.graphics.setColor(255, 255, 0)
    if hookActive then
        love.graphics.line(
            player.x + player.size / 2, -- x1 tocka
            player.y + player.size / 2, -- y1 tocka
            NonUpdateingX-100,  -- x2 tocka
            NonUpdateingY -- y2 tocka
         )
    end
    
    

    
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)

    
    if not itemz.collected then
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", itemz.x, itemz.y, itemz.size, itemz.size)
    end

    if not itemzD.collected then
        love.graphics.setColor(255, 0, 0)
        love.graphics.rectangle("line", itemzD.x, itemzD.y, itemzD.size, itemzD.size)
    end

    cam:detach()
end