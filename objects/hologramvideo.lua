local morolua = require("morolua-main.init")
local DATAFILE = "layout.lua"

local HologramVideo = morolua.oopx.class()

function HologramVideo:init(video, dist, cropPercent, scale)
    self.video = video
    self.dist = dist or 250
    self.scale = scale or 1
    self.center = { x = 400, y = 300 }
    self.editMode = false
    self.welded = true
    self.sides = { "north", "south", "east", "west" }
    self.selectedSide = "north"
    self.showHelp = false
    self._rTapCount = 0
    local vw, vh = video:getWidth(), video:getHeight()
    cropPercent = cropPercent or 0.35
    local cropW = vw * cropPercent
    local startX = (vw - cropW) / 2

    self.canvas = love.graphics.newCanvas(vw, vh)
    self.quad = love.graphics.newQuad(startX, 0, cropW, vh, vw, vh)

    
    self.sideData = {}
    for _, side in ipairs(self.sides) do
        local rot
        if side == "north" then rot = 0
        elseif side == "south" then rot = math.rad(180)
        elseif side == "east" then rot = math.rad(90)
        elseif side == "west" then rot = math.rad(-90) end

        self.sideData[side] = {
            dx = (side=="east" and dist or side=="west" and -dist or 0),
            dy = (side=="north" and -dist or side=="south" and dist or 0),
            rotation = rot,
            scale = self.scale
        }
    end
end

function HologramVideo:toggleHelp()
    self.showHelp = not self.showHelp
end

function HologramVideo:toggleEditMode()
    self.editMode = not self.editMode
end

function HologramVideo:toggleWelded()
    self.welded = not self.welded
end

function HologramVideo:selectNextSide()
    local i
    for idx, side in ipairs(self.sides) do
        if side == self.selectedSide then i = idx break end
    end
    i = (i % #self.sides) + 1
    self.selectedSide = self.sides[i]
end

function HologramVideo:update(dt)
    self:handleReset(dt)

    if not self.editMode then return end

    local moveSpeed = 200 * dt
    local scaleSpeed = 0.5 * dt
    local distSpeed = 100 * dt
    local rotSpeed = math.rad(90) * dt

    local moveX, moveY = 0,0
    if love.keyboard.isDown("up") then moveY = -moveSpeed end
    if love.keyboard.isDown("down") then moveY = moveSpeed end
    if love.keyboard.isDown("left") then moveX = -moveSpeed end
    if love.keyboard.isDown("right") then moveX = moveSpeed end

    if love.keyboard.isDown("z") then
        if self.welded then
            self.scale = self.scale - scaleSpeed
            for _, d in pairs(self.sideData) do d.scale = self.scale end
        else
            self.sideData[self.selectedSide].scale = self.sideData[self.selectedSide].scale - scaleSpeed
        end
    end
    if love.keyboard.isDown("x") then
        if self.welded then
            self.scale = self.scale + scaleSpeed
            for _, d in pairs(self.sideData) do d.scale = self.scale end
        else
            self.sideData[self.selectedSide].scale = self.sideData[self.selectedSide].scale + scaleSpeed
        end
    end

    if self.welded then
        self.center.x = self.center.x + moveX
        self.center.y = self.center.y + moveY
    else
        local d = self.sideData[self.selectedSide]
        d.dx = d.dx + moveX
        d.dy = d.dy + moveY
    end

    if love.keyboard.isDown("q") then
        local d = self.sideData[self.selectedSide]
        d.rotation = d.rotation - rotSpeed
    end
    if love.keyboard.isDown("e") then
        local d = self.sideData[self.selectedSide]
        d.rotation = d.rotation + rotSpeed
    end

    if love.keyboard.isDown("w") then
        if self.welded then
            for _, d in pairs(self.sideData) do
                local sign = (d.dy<0 or d.dx>0) and 1 or -1
                d.dx = d.dx + sign*distSpeed*dt
                d.dy = d.dy + sign*distSpeed*dt
            end
        else
            -- optinal side dist adjustment
        end
    end
    if love.keyboard.isDown("s") then
        if self.welded then
            for _, d in pairs(self.sideData) do
                local sign = (d.dy<0 or d.dx>0) and -1 or 1
                d.dx = d.dx + sign*distSpeed*dt
                d.dy = d.dy + sign*distSpeed*dt
            end
        end
    end
end

function HologramVideo:draw()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    love.graphics.draw(self.video, 0,0)
    love.graphics.setCanvas()

    local _,_,qw,qh = self.quad:getViewport()
    local cx, cy = self.center.x, self.center.y

    love.graphics.clear(0,0,0)

    for _, side in ipairs(self.sides) do
        local d = self.sideData[side]
        love.graphics.draw(
            self.canvas, self.quad,
            cx + d.dx, cy + d.dy,
            d.rotation,
            d.scale, d.scale,
            qw/2, qh/2
        )
    end
    --merkezi gösteren şey
    if self.editMode then
        love.graphics.setColor(1,0,0)
        love.graphics.circle("fill", cx, cy, 5)
        love.graphics.setColor(1,1,1)
    end

    if self.showHelp then
    love.graphics.setColor(0, 0, 0, 0.7) 
    love.graphics.rectangle("fill", 20, 20, 280, 220)
    love.graphics.setColor(1,1,1)

    local lines = {
        "Ayarlama",
        "",
        "M       : Düzenleme moduna girer",
        "Arrow   : Merkezi ya da seçilen videoyu oynat",
        "Z/X     : Video ölçeklendir",
        "Q/E     : Seçilen videoyu döndür",
        "W/S     : Uzaklığı ayarla (bağlı)",
        "TAB     : Video seçme",
        "T       : Bağlı/bağımsız değiştirmed",
        "P       : debug",
        "K       : Kaydet",
        "L       : Yükle",
        "R x3    : Varsayılana dön",
        "Y       : Bu menüyü aç"
    }

        for i, line in ipairs(lines) do
            love.graphics.print(line, 30, 30 + (i-1)*16)
        end
    end
end

function HologramVideo:printState()
    print("Center:", self.center.x, self.center.y)
    for _, side in ipairs(self.sides) do
        local d = self.sideData[side]
        print(side, "dx:", d.dx, "dy:", d.dy, "scale:", d.scale, "rot:", math.deg(d.rotation))
    end
end

function HologramVideo:save(filename)
    local data = {
        center = self.center,
        welded = self.welded,
        sideData = self.sideData
    }

    -- serialize 
    local function serialize(t, indent)
        indent = indent or ""
        local s = "{\n"
        local nextIndent = indent .. "  "
        for k,v in pairs(t) do
            local key = type(k)=="string" and string.format("[%q]", k) or "["..k.."]"
            if type(v)=="table" then
                s = s..nextIndent..key.."="..serialize(v, nextIndent)..",\n"
            elseif type(v)=="string" then
                s = s..nextIndent..key.."="..string.format("%q", v)..",\n"
            elseif type(v)=="boolean" or type(v)=="number" then
                s = s..nextIndent..key.."="..tostring(v)..",\n"
            else
                error("Unsupported value type: "..type(v))
            end
        end
        s = s..indent.."}"
        return s
    end

    local contents = "return "..serialize(data)
    love.filesystem.write(filename, contents)
end


function HologramVideo:load(filename)
    if not love.filesystem.getInfo(filename) then return end
    local contents = love.filesystem.read(filename)
    local chunk, err = load(contents)
    if not chunk then
        print("Error loading layout:", err)
        return
    end
    local data = chunk()
    self.center = data.center
    self.welded = data.welded
    self.sideData = data.sideData
end

function HologramVideo:handleReset(dt)
    if self._rTapCount > 0 then
        self._rTapTimer = self._rTapTimer + dt
        if self._rTapTimer > self._rTapMaxTime then
            self._rTapCount = 0
            self._rTapTimer = 0
        end
    end
end

function HologramVideo:onRTap()
    self._rTapCount = self._rTapCount + 1
    self._rTapTimer = 0

    if self._rTapCount >= 3 then
        self:reset()
        self._rTapCount = 0
        self._rTapTimer = 0
        print("Hologram reset to default!")
    end
end

function HologramVideo:reset()
    self.center.x = self._defaultData.center.x
    self.center.y = self._defaultData.center.y
    self.welded = self._defaultData.welded
    self.scale = self._defaultData.scale
    self.dist = self._defaultData.dist

    -- reset each sde offset and rotation
    for _, side in ipairs(self.sides) do
        local rot
        if side == "north" then rot = 0
        elseif side == "south" then rot = math.rad(180)
        elseif side == "east" then rot = math.rad(90)
        elseif side == "west" then rot = math.rad(-90) end

        self.sideData[side].dx = (side=="east" and self.dist or side=="west" and -self.dist or 0)
        self.sideData[side].dy = (side=="north" and -self.dist or side=="south" and self.dist or 0)
        self.sideData[side].rotation = rot
        self.sideData[side].scale = self.scale
    end
end

return HologramVideo
