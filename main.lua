local Camera = require "camera"
local cam
local anim8 = require "anim8"



function love.load()
    -- tiled map 
    sti = require 'sti'
    gameMap=sti('Maps/map.lua')

    -- wf physics 
    wf = require 'windfield'
    world = wf.newWorld(0,0)


    player = {
        
        x = 400,
        y = 200,
        speed = 300,
        size = 32,
        hp = 100,
        isdead = false 
    }
    -- player physics
    player.collider = world:newBSGRectangleCollider(400, 200, 40, 70, 0)
    player.collider:setFixedRotation(true)
    

    -- player animations
    love.graphics.setDefaultFilter("nearest", "nearest")
    player.spritesheet = love.graphics.newImage('sprites/player-sheet.png')
    player.grid = anim8.newGrid(12,18,player.spritesheet:getWidth(),player.spritesheet:getHeight())

    player.animations = {}
    player.animations.down = anim8.newAnimation(player.grid('1-4',1), 0.2)
    player.animations.left = anim8.newAnimation(player.grid('1-4',2), 0.2)
    player.animations.right = anim8.newAnimation(player.grid('1-4',3), 0.2)
    player.animations.up = anim8.newAnimation(player.grid('1-4',4), 0.2) 
    
    player.anim=player.animations.left

    -- wall phy 
    walls = {}
    if gameMap.layers["walls"] then
        for i, obj in pairs(gameMap.layers["walls"].objects) do
            local wall = world:newRectangleCollider(obj.x,obj.y,obj.width,obj.height)
            wall:setType('static')
            table.insert(walls,wall)
        end
    end

    local wall = world:newRectangleCollider(100,200,120,300)
    wall:setType('static')

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

    enemy = {
        x = love.math.random(0,1250),
        y = love.math.random(0,1250),
        dmg = 25,
        dmgCD = 0,
        dmgCDT = 0.8, -- enemy attack cd 
        speed = 500,
        size = 32,
        isdead=false
    }

    cam = Camera(player.x, player.y)

    
    hookActive = false
    hookSpeed = player.speed*2.5
    hookTargetX = 0
    hookTargetY = 0
    hookCooldown = 0
    hookCooldownTime = 0.8 -- cd  

    counter=0
    
    
end

function love.update(dt)
    gameMap:update(dt)
    local isMoving = false

    local vx=0
    local vy=0



    if enemy.dmgCD > 0 then
        enemy.dmgCD = enemy.dmgCD-dt
    end
    
    if hookCooldown > 0 then
        hookCooldown = hookCooldown - dt
    end

    local dx, dy = 0, 0

    if love.keyboard.isDown("w") then 
        dy = dy - 1 
        player.anim=player.animations.up
        isMoving=true
    end
    if love.keyboard.isDown("s") then 
        dy = dy + 1 
        player.anim=player.animations.down
        isMoving=true
    end
    if love.keyboard.isDown("a") then 
        dx = dx - 1
        player.anim=player.animations.left
        isMoving=true
    end
    if love.keyboard.isDown("d") then 
        dx = dx + 1
        player.anim=player.animations.right
        isMoving=true 
    end

    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx*dx + dy*dy)
        dx = dx / len
        dy = dy / len
        player.collider:setLinearVelocity(dx * player.speed, dy * player.speed)
    else
        player.collider:setLinearVelocity(0, 0)
        player.anim:gotoFrame(2)
    end

    if isMoving == false then
        player.anim:gotoFrame(2)
    end

    -- libary updates 
    world:update(dt)
    player.x =player.collider:getX()
    player.y=player.collider:getY()
    player.anim:update(dt)

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
        enemy.x = love.math.random(0,1250)
        enemy.y = love.math.random(0,1250)
    end

    
    if love.keyboard.isDown("x") then
        if counter==0 then
            enemy.speed=0
            counter=counter+1
        end
    else if counter>0 then
            enemy.speed=500
            counter=0
        end
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

    
    -- player.x = math.max(terrain.x, math.min(player.x, terrain.x + terrain.size - player.size))
    -- player.y = math.max(terrain.y, math.min(player.y, terrain.y + terrain.size - player.size))

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

    if enemy.isdead==false then
    
    local dx1 = player.x - enemy.x
    local dy1 = player.y - enemy.y

    
    local distance = math.sqrt(dx1 * dx1 + dy1 * dy1)

    
    if distance > 0 then
        enemy.x = enemy.x + (dx1 / distance) * enemy.speed * dt
        enemy.y = enemy.y + (dy1 / distance) * enemy.speed * dt
    end
    end

        
       if player.x < enemy.x + enemy.size and
       enemy.dmgCD <= 0 and
        player.x + enemy.size > enemy.x and
        player.y < enemy.y + enemy.size and
        player.y + enemy.size > enemy.y then

        player.hp = player.hp - enemy.dmg
        enemy.dmgCD=enemy.dmgCDT
        end
        

    
    if player.hp <= 0 then
        player.isdead = true
        player.speed=0
    end


end


function love.draw()
    cam:attach()

    love.graphics.setColor(255, 255, 255)
    gameMap:draw(-cam.x + love.graphics.getWidth()/2, -cam.y + love.graphics.getHeight()/2)

    if player.isdead then
        love.graphics.setColor(255, 0, 0)
        love.graphics.print("DEAD", player.x, player.y - 50)
    end

    if hookActive then
        love.graphics.setColor(255, 255, 0)
        love.graphics.line(
            player.x + 24,
            player.y + 36,
            NonUpdateingX - 100,
            NonUpdateingY
        )
    end

    love.graphics.setColor(255, 255, 255)
    local px = player.collider:getX()
    local py = player.collider:getY()
    player.anim:draw(player.spritesheet, px - 24, py - 36, nil, 4)

    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.size, enemy.size)

    if not itemz.collected then
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", itemz.x, itemz.y, itemz.size, itemz.size)
    end

    if not itemzD.collected then
        love.graphics.setColor(255, 0, 0)
        love.graphics.rectangle("line", itemzD.x, itemzD.y, itemzD.size, itemzD.size)
    end

    world:draw()
    cam:detach()
end
