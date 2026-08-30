function love.load()
    x = 5
    y = 5
end

function love.update(dt)
    if love.keyboard.isDown("right") then
        x = x + 200 * dt
    elseif love.keyboard.isDown("left") then
        x = x - 200 * dt
    end
    
    if love.keyboard.isDown("up") then
        y = y - 200 * dt
    elseif love.keyboard.isDown("down") then
        y = y + 200 * dt
    end
end

function love.draw()
    love.graphics.rectangle("line", x, y, 200, 150)
end