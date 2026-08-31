function love.load()
    circle = {}

    circle.x = 100
    circle.y = 100
    circle.radius = 25
    circle.speed = 200
end

function getDistance(x1, y1, x2, y2)
    local horizontal_distance = x1 - x2
    local vertical_distance = y1 - y2
    local a = horizontal_distance * horizontal_distance
    local b = vertical_distance * vertical_distance

    local c = a + b
    local distance = math.sqrt(c)
    return distance
end

function love.update(dt)
    mouse_x, mouse_y = love.mouse.getPosition()
    angle = math.atan2(mouse_y - circle.y, mouse_x - circle.x)
    cos = math.cos(angle)
    sin = math.sin(angle)

    local distance = getDistance(circle.x, circle.y, mouse_x, mouse_y)

    -- enemy only moves if player actor is within 200 pixels
    if distance < 200 then
        circle.x = circle.x + circle.speed * cos * (distance/100) * dt
        circle.y = circle.y + circle.speed * sin * (distance/100) * dt
    end
end

function love.draw()
    local distance = getDistance(circle.x, circle.y, mouse_x, mouse_y)

    local detectionRange = 200
    local t = 1 - math.min(distance / detectionRange, 1)

    local r = t
    local g = 1 - t
    local b = 0

    love.graphics.setColor(r, g, b)
    love.graphics.circle("line", circle.x, circle.y, circle.radius)

    love.graphics.setColor(1, 1, 1)
    love.graphics.line(circle.x, circle.y, mouse_x, mouse_y)
    love.graphics.line(circle.x, circle.y, mouse_x, circle.y)
    love.graphics.line(mouse_x, mouse_y, mouse_x, circle.y)

    love.graphics.setColor(r, g, b, 0.5)
    love.graphics.circle("line", circle.x, circle.y, distance)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Distance: " .. math.floor(distance), 10, 10)

    local statusText = (distance < detectionRange) and "CHASING" or "IDLE"
    local font = love.graphics.getFont()
    local scale = 3 

    local textWidth = font:getWidth(statusText) * scale
    local textHeight = font:getHeight() * scale

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    love.graphics.setColor(r, g, b)
    love.graphics.print(
        statusText,
        screenW / 2 - textWidth / 2,
        screenH / 2 - textHeight / 2,
        0,     
        scale, scale 
    )
end