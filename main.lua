local Camera = require "camera"
local cam
local anim8 = require "anim8"
local GrapplingHook = require "grappling_hook"
local reset = require "reset"
local freeze = require "freeze"

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
        isleft = false,
        range = 200,
        rangeY=range,
        rangeX=range

    }
    -- player physics
    world:addCollisionClass('Enemys')
    world:addCollisionClass('Movers',{ignores={'Enemys'}})
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

    enemies = {}
    for i = 1, 5 do
        local enemy = {
            x = love.math.random(0,1250),
            y = love.math.random(0,1250),
            dmg = 10,
            dmgCD = 0,
            dmgCDT = 0.8, -- enemy attack cd 
            speed = 250,
            size = 32,
            isdead=false,
            hp = 50
        }

        -- enemy phy
        enemy.collider=world:newBSGRectangleCollider(enemy.x,enemy.y,32,40,0)
        enemy.collider:setFixedRotation(true)
        enemy.collider:setCollisionClass('Enemys')

        enemy.spritesheet = love.graphics.newImage('sprites/enemysprite.png')
        enemy.grid=anim8.newGrid(15,17,enemy.spritesheet:getWidth(),enemy.spritesheet:getHeight(),0,0,0)
        enemy.animations = {}
        enemy.animations.left=anim8.newAnimation(enemy.grid('1-4',1), 0.1)
        enemy.anim=enemy.animations.left

        table.insert(enemies, enemy)
    end

    -- ======
    cam = Camera(player.x, player.y)
    -- ======

    
    hook = GrapplingHook.init(player)

    counter=0
    
    isEnemyFrozen = false

    weapon = {
        damage = 10,
        damageCD = 0,
        ProjSpeed = 550,
        isShooting = false
    }

    projectiles = {}
    
end

function love.update(dt)
    gameMap:update(dt)
    local isMoving = false

    for _, enemy in ipairs(enemies) do
        if enemy.hp <=0 then
            enemy.isdead=true
            enemy.collider:setLinearVelocity(0, 0)
            enemy.dmg=0
        end
    end

    -- cds 
    if weapon.damageCD > 0 then
        weapon.damageCD = weapon.damageCD-dt
    end

    for _, enemy in ipairs(enemies) do
        if enemy.dmgCD > 0 then
            enemy.dmgCD = enemy.dmgCD-dt
        end
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
    for _, enemy in ipairs(enemies) do
        enemy.x=enemy.collider:getX()
        enemy.y=enemy.collider:getY()
    end

    player.anim:update(dt)
    for _, enemy in ipairs(enemies) do
        enemy.anim:update(dt)
    end

    if not hook.active then
        player.x = player.x + dx * player.speed * dt
        player.y = player.y + dy * player.speed * dt
    end

    GrapplingHook.update(hook, player, dt, cam)

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

    for _, enemy in ipairs(enemies) do
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
    end

    for _, enemy in ipairs(enemies) do        
       if player.x < enemy.x + enemy.size and
       enemy.dmgCD <= 0 and
        player.x + enemy.size > enemy.x and
        player.y < enemy.y + enemy.size and
        player.y + enemy.size > enemy.y then

        player.hp = player.hp - enemy.dmg
        enemy.dmgCD=enemy.dmgCDT
        end
    end
        

    
    if player.hp <= 0 then
        player.isdead = true
        player.speed=0
    end

    if weapon.damageCD <= 0 then
        local closestEnemy = nil
        local closestDistance = player.range + 1
        
        for _, enemy in ipairs(enemies) do
            if not enemy.isdead then
                local dx = enemy.x - player.x
                local dy = enemy.y - player.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                if distance <= player.range and distance < closestDistance then
                    closestEnemy = enemy
                    closestDistance = distance
                end
            end
        end
        
        if closestEnemy then
            local dx = closestEnemy.x - player.x
            local dy = closestEnemy.y - player.y
            local len = math.sqrt(dx*dx + dy*dy)
            dx = dx / len
            dy = dy / len
            
            local proj = {
                x = player.x,
                y = player.y,
                vx = dx * weapon.ProjSpeed,
                vy = dy * weapon.ProjSpeed
            }
            table.insert(projectiles, proj)
            weapon.damageCD = 0.35
        end
    end

    for i = #projectiles, 1, -1 do
        local proj = projectiles[i]
        proj.x = proj.x + proj.vx * dt
        proj.y = proj.y + proj.vy * dt
        
        local hit = false
        for _, enemy in ipairs(enemies) do
            if not enemy.isdead then
                local grace = 10
                if proj.x < enemy.x + enemy.size + grace and
                   proj.x + 3 > enemy.x - grace and
                   proj.y < enemy.y + enemy.size + grace and
                   proj.y + 3 > enemy.y - grace then
                    enemy.hp = enemy.hp - weapon.damage
                    hit = true
                    break
                end
            end
        end
        
        if hit or proj.x < 0 or proj.x > 1900 or proj.y < 80 or proj.y > 1800 then
            table.remove(projectiles, i)
        end
    end

end


function love.keypressed(key)
    if key == "x" then
        freeze.toggleEnemyFreeze()
    end
    if key == "r" then
        reset.resetGame(player, itemz, itemzD, GrapplingHook, hook, enemies, projectiles)
    end
end


function love.draw()
    cam:attach()

    love.graphics.setColor(1, 1, 1, 1)
    gameMap:draw(-cam.x + love.graphics.getWidth()/2, -cam.y + love.graphics.getHeight()/2)

    if player.isdead then
        love.graphics.setColor(1, 0, 0, 1)  
        love.graphics.print("DEAD", player.x, player.y - 50)
    end

    GrapplingHook.draw(hook, player)

    love.graphics.setColor(1, 1, 1, 1)
    local px = player.collider:getX()
    local py = player.collider:getY()
    if player.isleft==false then
        player.anim:draw(player.spritesheet, px - 20, py - 38, nil, 3, 3)
        love.graphics.circle("line",px,py,player.range)
    else
        player.anim:draw(player.spritesheet, px + 20, py - 38, nil, -3, 3)
        love.graphics.circle("line",px,py,player.range)
    end
    
    local playerHealthPercent = player.hp / 100
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("fill", px - 16, py - 50, 32 * playerHealthPercent, 4)

    love.graphics.setColor(1, 1, 1, 1)
    for _, enemy in ipairs(enemies) do
        local ex, ey = enemy.collider:getPosition()
        if enemy.isdead ==false then
        if enemy.x<player.x then
        enemy.anim:draw(enemy.spritesheet, ex-20,ey-38,nil,3,3)
        else
            enemy.anim:draw(enemy.spritesheet,ex+20,ey-38,nil,-3,3)
        end
        
        local healthPercent = enemy.hp / 50
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle("fill", ex - 16, ey - 50, 32 * healthPercent, 4)
        love.graphics.setColor(1, 1, 1, 1)
        end
    end

    if not itemz.collected then
        love.graphics.setColor(0, 0, 0, 1)  
        love.graphics.rectangle("line", itemz.x, itemz.y, itemz.size, itemz.size)
    end

    if not itemzD.collected then
        love.graphics.setColor(1, 0, 0, 1) 
        love.graphics.rectangle("line", itemzD.x, itemzD.y, itemzD.size, itemzD.size)
    end

    for _, proj in ipairs(projectiles) do
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.circle("fill", proj.x, proj.y, 5)
    end

    -- world:draw()
    cam:detach()
    -- cords 
    love.graphics.setColor(1, 0, 0, 1)  
    love.graphics.print("X: "..math.floor(player.x).." Y: "..math.floor(player.y), love.graphics.getWidth() - 150, 10)

end