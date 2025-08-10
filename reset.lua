local reset = {}

function reset.resetGame(player, itemz, itemzD, GrapplingHook, hook, enemies, projectiles)
    player.x = player.collider:getX()
    player.y = player.collider:getY()
    player.speed = 300
    player.hp = 100  
    itemz.collected = false
    itemzD.collected = false  
    GrapplingHook.reset(hook)
    player.isdead = false  
    
    for _, enemy in ipairs(enemies) do
        if enemy.collider then
            enemy.x = love.math.random(0,1250)
            enemy.y = love.math.random(0,1250)
            enemy.collider:setPosition(enemy.x, enemy.y)
            enemy.collider:setLinearVelocity(0, 0)
        end
        enemy.isdead=false
        enemy.hp = 50
    end
    
    for i = #projectiles, 1, -1 do
        table.remove(projectiles, i)
    end
end

return reset