local HologramVideo = require("objects.hologramvideo")
local video
local holo

function love.load()
    video = love.graphics.newVideo("videos/video.ogv")
    video:play()
    holo = HologramVideo:new(video, 250, 0.35, 1)
end

function love.update(dt)
    holo:update(dt)
end

function love.draw()
    holo:draw()
end

function love.keypressed(key)
    if key == "m" then holo:toggleEditMode() end
    if key == "t" then holo:toggleWelded() end
    if key == "tab" then holo:selectNextSide() end
    if key == "p" then holo:printState() end
    if key == "l" then holo:load("layout.lua") end
    if key == "k" then holo:save("layout.lua") end

    if key == "r" then
        holo:onRTap()
    end
end--wip
