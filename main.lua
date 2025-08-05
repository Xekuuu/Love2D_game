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
        isdead = false, 
        isleft = false
    }
    -- player physics
    world:addCollisionClass('Movers',{ignores={'Movers'}})
    player.collider = world:newBSGRectangleCollider(400, 200, 32, 40, 0)
    player.collider:setFixedRotation(true)
    player.collider:setCollisionClass('Movers')
    
    


    -- player animations
    love.graphics.setDefaultFilter("nearest", "nearest")
    player.spritesheet = love.graphics.newImage('sprites/wizardsprite.png')
    player.grid = anim8.newGrid(16,22,player.spritesheet:getWidth(),player.spritesheet:getHeight(),0,4,0)

    player.animations = {}
    player.animations.left = anim8.newAnimation(player.grid('1-6',1), 0.1)
    player.animations.right = anim8.newAnimation(player.grid('1-6',1), 0.1)
        
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


    -- enemy phy
    enemy.collider=world:newBSGRectangleCollider(enemy.x,enemy.y,32,40,0)
    enemy.collider:setFixedRotation(true)
    enemy.collider:setCollisionClass('Movers')

    -- ======
    cam = Camera(player.x, player.y)
    -- ======


    -- enemy animations 

    --    -- player animations
    -- love.graphics.setDefaultFilter("nearest", "nearest")
    -- player.spritesheet = love.graphics.newImage('sprites/wizardsprite.png')
    -- player.grid = anim8.newGrid(16,22,player.spritesheet:getWidth(),player.spritesheet:getHeight(),0,4,0)

    -- player.animations = {}
    -- player.animations.left = anim8.newAnimation(player.grid('1-6',1), 0.1)
    -- player.animations.right = anim8.newAnimation(player.grid('1-6',1), 0.1)
        
    -- player.anim=player.animations.left

    enemy.spritesheet = love.graphics.newImage('sprites/enemysprite.png')
    enemy.grid=anim8.newGrid(15,17,enemy.spritesheet:getWidth(),enemy.spritesheet:getHeight(),0,0,0)
    enemy.animations = {}
        enemy.animations.left=anim8.newAnimation(enemy.grid('1-4',1), 0.1)

    enemy.anim=enemy.animations.left
    

    
    hookActive = false
    hookSpeed = player.speed*2.5
    hookTargetX = 0
    hookTargetY = 0
    hookCooldown = 0
    hookCooldownTime = 0.8 -- cd  

    counter=0
    
    isEnemyFrozen = false
    
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
        isMoving=true
        player.isleft=false
    end
    if love.keyboard.isDown("s") then 
        dy = dy + 1 
        isMoving=true
        player.isleft=false
    end
    if love.keyboard.isDown("a") then 
        dx = dx - 1
        player.anim=player.animations.left
        isMoving=true
        player.isleft=true
    end
    if love.keyboard.isDown("d") then 
        dx = dx + 1
        player.anim=player.animations.right
        isMoving=true
        player.isleft=false
    end

    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx*dx + dy*dy)
        dx = dx / len
        dy = dy / len
        player.collider:setLinearVelocity(dx * player.speed, dy * player.speed)
    else
        player.collider:setLinearVelocity(0, 0)
        player.anim:gotoFrame(1)
    end

    if isMoving == false then
        player.anim:gotoFrame(1)
    end

    -- libary updates 
    world:update(dt)
    player.x =player.collider:getX()
    player.y=player.collider:getY()

    -- enemy phy
    enemy.x=enemy.collider:getX()
    enemy.y=enemy.collider:getY()

    player.anim:update(dt)
    enemy.anim:update(dt)

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

    if enemy.isdead == false and not isEnemyFrozen then
    local dx = player.x - enemy.x
    local dy = player.y - enemy.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 0 then
        dx = dx / dist
        dy = dy / dist
        enemy.collider:setLinearVelocity(dx * enemy.speed, dy * enemy.speed)
        enemy.anim=enemy.animations.left
    else
        enemy.collider:setLinearVelocity(0, 0)
    end
elseif isEnemyFrozen then
    enemy.collider:setLinearVelocity(0, 0)
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

function love.keypressed(key)
    if key == "x" then
        isEnemyFrozen = not isEnemyFrozen
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
    if player.isleft==false then
        player.anim:draw(player.spritesheet, px - 20, py - 38, nil, 3, 3)
    else
        player.anim:draw(player.spritesheet, px + 20, py - 38, nil, -3, 3)
    end

    love.graphics.setColor(255, 0, 0)
    local ex, ey = enemy.collider:getPosition()
    if enemy.isdead ==false then
    -- love.graphics.rectangle("fill", ex - enemy.size/2, ey - enemy.size/2, enemy.size, enemy.size)
    enemy.anim:draw(enemy.spritesheet, ex-20,ey-38,nil,3,3)
    end

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