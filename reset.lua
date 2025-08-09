local reset = {}

function reset.resetGame(player, enemy, itemz, itemzD, projectiles, hook)
    player.x = player.collider:getX()
    player.y = player.collider:getY()
    player.speed = 300
    player.hp = 100  
    itemz.collected = false
    itemzD.collected = false  
    GrapplingHook.reset(hook)
    player.isdead = false  
    enemy.x = love.math.random(0,1250)
    enemy.y = love.math.random(0,1250)
    enemy.collider:setPosition(enemy.x, enemy.y)
    enemy.collider:setLinearVelocity(0, 0)
    enemy.isdead = false
    enemy.hp = 50
    enemy.dmg = 25
    for i = #projectiles, 1, -1 do
        projectiles[i] = nil
    end
end

return reset