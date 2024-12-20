-- Copyright (c) 2024 Daniele Tabanella under the MIT license

cls()

-- Constants
local levelWidth = nil
local levelHeight = nil
local rules = nil
local level = nil
local ruledlevel = nil
local skip = nil

-- do this programmatically
local directions = {
    [1] = { { 0, 0 } },
    [3] = {},
    [5] = {}
}

for y = -1, 1 do
    for x = -1, 1 do
        add(directions[3], { x, y })
    end
end

for y = -2, 2 do
    for x = -2, 2 do
        add(directions[5], { x, y })
    end
end

-- Tiles

function initAutotiles(newRules, newLevelWidth, newLevelHeight)
    levelWidth = newLevelWidth
    levelHeight = newLevelHeight
    level = create2DArr(levelWidth, levelHeight, 0)
    ruledlevel = create2DArr(levelWidth, levelHeight, 0)
    skip = create2DArr(levelWidth, levelHeight, false)
    rules = newRules
end

function setTiles()
    forEachArr2D(
        level, function(x, y)
            setTileAt(x, y)
        end
    )
end

function isInBounds(x, y)
    return x <= levelWidth and y <= levelHeight and x > 0 and y > 0
end

function setTileAt(x, y)
    if level[x][y] == 0 or skip[x][y] then
        return
    end
    for ruleGroup in all(rules) do
        for rule in all(ruleGroup) do
            local active = rule.active or true
            if active then
                local match = false
                local size = ({[1] = 1, [9] = 3, [25] = 5})[#rule.pattern] or 1
                for i = 1, #directions[size] do
                    local pos = directions[size][i]
                    local dx = pos[1]
                    local dy = pos[2]
                    local tile = rule.pattern[i]
                    if isInBounds(x + dx, y + dy) then
                        -- if the tile is 'all' then it will match any tile
                        -- if the tile is a number then it will match that specific tile
                        -- if the tile is a negative number then it will match any tile except that specific tile
                        if tile == 'all' or (tile > 0 and level[x + dx][y + dy] == tile) or (tile < 0 and level[x + dx][y + dy] != -tile) then
                            match = true
                        else
                            match = false
                            break
                        end
                    else
                        -- if the tile is out of bounds then it will match only if the tile is 'all'
                        if tile == 'all' then
                            match = true
                        else
                            match = false
                            break
                        end
                    end
                end
                if match then
                    local chance = rule.chance or 1
                    if rnd() < chance then
                        if rule.block then
                            local blockHeight = #rule.block
                            local blockWidth = #rule.block[1]
                            local offX = rule.offsetX or 0
                            local offY = rule.offsetY or 0
                            local startX = x + offX
                            local startY = y + offY
                            for dy = 1, blockHeight do
                                for dx = 1, blockWidth do
                                    ruledlevel[startX + dx - 1][startY + dy - 1] = rule.block[dy][dx]
                                    -- we don't want to check these tiles again
                                    skip[startX + dx - 1][startY + dy - 1] = true
                                end
                            end
                        elseif rule.sprites then
                            local sprite = getRandomItem(rule.sprites)
                            ruledlevel[x][y] = sprite
                        end
                        if rule.stopOnMatch then
                            -- if stopOnMatch is true then it will stop checking the other rules
                            break
                        end
                    end
                end
            end
        end
    end
end

function readPixelMap(startX, startY, endX, endY)
    -- read pixels from sprite sheet
    -- from y=64 to 81 and from x=0 to 32
    for x = startX, endX do
        for y = startY, endY do
            local color = sget(x, y)
            level[x - startX + 1][y - startY + 1] = color
        end
    end
end

function drawMiniMap(dx, dy)
    forEachArr2D(
        level, function(x, y)
            local color = level[x][y]
            if color != nil and color != 0 then
                pset(x - 1 + dx, y - 1 + dy, level[x][y])
            end
        end
    )
end

function createMap()
    forEachArr2D(
        ruledlevel, function(x, y)
            mset(x - 1, y - 1, ruledlevel[x][y])
        end
    )
end
