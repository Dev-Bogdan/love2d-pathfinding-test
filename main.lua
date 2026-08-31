function love.load()
    circle = {}
    circle.x = 100
    circle.y = 100
    circle.radius = 25
    circle.speed = 200

    player = {}
    player.x = 600
    player.y = 400
    player.radius = 10
    player.speed = 250

    obstacle = { x = 350, y = 250, width = 100, height = 100 }

    state = "IDLE"
    lastKnownX = nil
    lastKnownY = nil

    searchDelay = 0.75
    searchTimer = 0
    arrivedAtLastKnown = false

    facingAngle = 0
    fovAngle = math.rad(45)
    detectionRange = 200

    baseFacingAngle = 0
    sweepRange = math.rad(60)
    sweepSpeed = 1.2
    sweepTime = 0

    losLostGrace = 0.2
    losLostTimer = 0

    alertTimer = 0
    alertDuration = 0.6

    shakeTimer = 0
    shakeDuration = 0.3
    shakeMagnitude = 6
    shakeOffsetX = 0
    shakeOffsetY = 0
end

function getDistance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

function angleDiff(a, b)
    local diff = (a - b) % (2 * math.pi)
    if diff > math.pi then diff = diff - 2 * math.pi end
    return diff
end

function segmentsIntersect(x1, y1, x2, y2, x3, y3, x4, y4)
    local d1x, d1y = x2 - x1, y2 - y1
    local d2x, d2y = x4 - x3, y4 - y3
    local denom = d1x * d2y - d1y * d2x
    if denom == 0 then return false end

    local t = ((x3 - x1) * d2y - (y3 - y1) * d2x) / denom
    local u = ((x3 - x1) * d1y - (y3 - y1) * d1x) / denom
    return t >= 0 and t <= 1 and u >= 0 and u <= 1
end

function lineIntersectsRect(x1, y1, x2, y2, rx, ry, rw, rh)
    local left   = segmentsIntersect(x1, y1, x2, y2, rx, ry, rx, ry + rh)
    local right  = segmentsIntersect(x1, y1, x2, y2, rx + rw, ry, rx + rw, ry + rh)
    local top    = segmentsIntersect(x1, y1, x2, y2, rx, ry, rx + rw, ry)
    local bottom = segmentsIntersect(x1, y1, x2, y2, rx, ry + rh, rx + rw, ry + rh)
    return left or right or top or bottom
end

function resolveCircleRectCollision(circ, rect)
    local closestX = math.max(rect.x, math.min(circ.x, rect.x + rect.width))
    local closestY = math.max(rect.y, math.min(circ.y, rect.y + rect.height))

    local dx = circ.x - closestX
    local dy = circ.y - closestY
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist < circ.radius then
        if dist > 0 then
            local overlap = circ.radius - dist
            circ.x = circ.x + (dx / dist) * overlap
            circ.y = circ.y + (dy / dist) * overlap
        else
            circ.y = circ.y - circ.radius
        end
    end
end

function love.update(dt)
    local moveX, moveY = 0, 0

    if love.keyboard.isDown("left") then moveX = moveX - 1 end
    if love.keyboard.isDown("right") then moveX = moveX + 1 end
    if love.keyboard.isDown("up") then moveY = moveY - 1 end
    if love.keyboard.isDown("down") then moveY = moveY + 1 end

    if moveX ~= 0 or moveY ~= 0 then
        local len = math.sqrt(moveX * moveX + moveY * moveY)
        moveX = moveX / len
        moveY = moveY / len
    end

    player.x = player.x + moveX * player.speed * dt
    player.y = player.y + moveY * player.speed * dt

    resolveCircleRectCollision(player, obstacle)

    local distance = getDistance(circle.x, circle.y, player.x, player.y)
    local angleToPlayer = math.atan2(player.y - circle.y, player.x - circle.x)

    local blocked = lineIntersectsRect(circle.x, circle.y, player.x, player.y,
                                        obstacle.x, obstacle.y, obstacle.width, obstacle.height)
    local withinRange = distance < detectionRange
    local withinCone = math.abs(angleDiff(angleToPlayer, facingAngle)) < fovAngle
    local hasLOS = withinRange and not blocked and withinCone

    local previousState = state

    if hasLOS then
        if state ~= "CHASING" then
            alertTimer = alertDuration
            shakeTimer = shakeDuration
        end
        state = "CHASING"
        lastKnownX, lastKnownY = player.x, player.y
        arrivedAtLastKnown = false
        searchTimer = 0
        losLostTimer = 0

    elseif state == "CHASING" then
        losLostTimer = losLostTimer + dt
        if losLostTimer >= losLostGrace then
            state = "SEARCHING"
            arrivedAtLastKnown = false
            searchTimer = 0
        end
    end

    if alertTimer > 0 then
        alertTimer = alertTimer - dt
    end

    if shakeTimer > 0 then
        shakeTimer = shakeTimer - dt
        local falloff = shakeTimer / shakeDuration
        shakeOffsetX = (love.math.random() * 2 - 1) * shakeMagnitude * falloff
        shakeOffsetY = (love.math.random() * 2 - 1) * shakeMagnitude * falloff
    else
        shakeOffsetX = 0
        shakeOffsetY = 0
    end

    if previousState == "CHASING" and state ~= "CHASING" then
        baseFacingAngle = facingAngle
        sweepTime = 0
    end

    if state == "CHASING" then
        facingAngle = angleToPlayer
    else
        sweepTime = sweepTime + dt
        facingAngle = baseFacingAngle + math.sin(sweepTime * sweepSpeed) * sweepRange
    end

    if state == "CHASING" then
        circle.x = circle.x + circle.speed * math.cos(angleToPlayer) * (distance / 100) * dt
        circle.y = circle.y + circle.speed * math.sin(angleToPlayer) * (distance / 100) * dt

    elseif state == "SEARCHING" then
        local d = getDistance(circle.x, circle.y, lastKnownX, lastKnownY)

        if d < 5 then
            arrivedAtLastKnown = true
        else
            local angle = math.atan2(lastKnownY - circle.y, lastKnownX - circle.x)
            circle.x = circle.x + circle.speed * math.cos(angle) * dt
            circle.y = circle.y + circle.speed * math.sin(angle) * dt
        end

        if arrivedAtLastKnown then
            searchTimer = searchTimer + dt
            if searchTimer >= searchDelay then
                state = "IDLE"
            end
        end
    end

    resolveCircleRectCollision(circle, obstacle)
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(shakeOffsetX, shakeOffsetY)

    local r, g, b = 0, 1, 0
    if state == "CHASING" then
        r, g, b = 1, 0, 0
    elseif state == "SEARCHING" then
        r, g, b = 1, 1, 0
    end

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("fill", obstacle.x, obstacle.y, obstacle.width, obstacle.height)

    love.graphics.setColor(r, g, b, 0.25)
    love.graphics.arc("fill", "pie", circle.x, circle.y, detectionRange,
                       facingAngle - fovAngle, facingAngle + fovAngle)

    love.graphics.setColor(r, g, b, 0.6)
    love.graphics.arc("line", "open", circle.x, circle.y, detectionRange,
                       facingAngle - fovAngle, facingAngle + fovAngle)

    love.graphics.setColor(r, g, b)
    love.graphics.circle("line", circle.x, circle.y, circle.radius)

    if state == "SEARCHING" and lastKnownX then
        love.graphics.setColor(1, 1, 0, 0.4)
        love.graphics.circle("line", lastKnownX, lastKnownY, 8)
    end

    love.graphics.setColor(0, 1, 1)
    love.graphics.circle("fill", player.x, player.y, player.radius)

    if alertTimer > 0 then
        local font = love.graphics.getFont()
        local scale = 2
        local w = font:getWidth("!") * scale
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("!", circle.x - w / 2, circle.y - circle.radius - 40, 0, scale, scale)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Distance: " .. math.floor(getDistance(circle.x, circle.y, player.x, player.y)), 10, 10)

    local font = love.graphics.getFont()
    local scale = 3
    local textWidth = font:getWidth(state) * scale
    local screenW = love.graphics.getWidth()
    local topMargin = 40

    love.graphics.setColor(r, g, b)
    love.graphics.print(state, screenW / 2 - textWidth / 2, topMargin, 0, scale, scale)

    love.graphics.pop()
end