local GrapplingHook = {}

function GrapplingHook.init(player)
    local hook = {
        active = false,
        speed = player.speed * 2.5,
        targetX = 0,
        targetY = 0,
        cooldown = 0,
        cooldownTime = 0.8,
        nonUpdatingX = 0,
        nonUpdatingY = 0
    }
    return hook
end

function GrapplingHook.update(hook, player, dt, cam)
    if hook.cooldown > 0 then
        hook.cooldown = hook.cooldown - dt
    end

    if love.keyboard.isDown("space") and not hook.active and hook.cooldown <= 0 then
        local mouseX, mouseY = love.mouse.getPosition()
        
        hook.targetX = mouseX + cam.x - love.graphics.getWidth()/2
        hook.targetY = mouseY + cam.y - love.graphics.getHeight()/2
        
        hook.nonUpdatingX = hook.targetX
        hook.nonUpdatingY = hook.targetY
        
        hook.active = true
        hook.cooldown = hook.cooldownTime  
    end

    if hook.active then
        local hx = hook.targetX - player.x
        local hy = hook.targetY - player.y
        local distance = math.sqrt(hx*hx + hy*hy)

        if distance > 2 then
            local nx = hx / distance
            local ny = hy / distance
            player.x = player.x + nx * hook.speed * dt
            player.y = player.y + ny * hook.speed * dt
            player.collider:setPosition(player.x, player.y)
        else
            player.x = hook.targetX
            player.y = hook.targetY
            player.collider:setPosition(hook.targetX, hook.targetY)
            hook.active = false
        end
    end
end

function GrapplingHook.draw(hook, player)
    if hook.active then
        love.graphics.setColor(255, 255, 0)
        love.graphics.line(
            player.x + 16,
            player.y + 20,
            hook.nonUpdatingX,
            hook.nonUpdatingY
        )
    end
end

function GrapplingHook.reset(hook)
    hook.active = false
    hook.targetX = 0
    hook.targetY = 0
    hook.cooldown = 0
end

return GrapplingHook