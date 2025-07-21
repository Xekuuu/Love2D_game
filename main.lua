function love.load()
    player = {
        x = 100,
        y = 100,
        speed = 300,
        size = 32
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
end




function love.draw()
    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)
end
