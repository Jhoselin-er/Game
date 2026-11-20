-- Game Entities
local Story = require("tinta.love")
local json = require("libraries/json")
local player = {}
local npc = {}

--ink
local dialogue = {
    active = false,
    text = "",
    choices = {},
    rawStory = nil,
    currentKnot = nil
}

function love.load()
    camera = require 'libraries/camera'
    cam = camera()

    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")

    sti = require 'libraries/sti'
    gameMap = sti('maps/testmap.lua')

    player = {}
    player.x = 400
    player.y = 200
    player.speed = 3
    player.spriteSheet = love.graphics.newImage('sprites/player-sheet.png')
    player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight() )

    player.animations = {}
    player.animations.down = anim8.newAnimation( player.grid('1-4', 1), 0.2)
    player.animations.left= anim8.newAnimation( player.grid('1-4', 2), 0.2)
    player.animations.right = anim8.newAnimation( player.grid('1-4', 3), 0.2)
    player.animations.up = anim8.newAnimation( player.grid('1-4', 4), 0.2)


    player.anim = player.animations.left
    --Npc
    npc.x = 480
    npc.y = 200
    npc.spriteSheet = love.graphics.newImage("sprites/player-npc-sheet.png")
    npc.grid = anim8.newGrid(12, 18, npc.spriteSheet:getWidth(), npc.spriteSheet:getHeight())
    npc.anim = anim8.newAnimation(npc.grid("1-4", 1), 0.2)
    npc.inkFile = "dialogue/suspect.json"

    local storyDefinition = import("dialogue/suspect")
    story = Story(storyDefinition)



end

function love.update(dt)
    if dialogue.active then 
        return
    end

    local isMoving = false

    if love.keyboard.isDown("right")then 
    player.x = player.x + player.speed
    player.anim = player.animations.right
    isMoving = true
end
    if love.keyboard.isDown("left")then 
    player.x = player.x - player.speed
    player.anim = player.animations.left
    isMoving = true
 end
    if love.keyboard.isDown("down")then 
    player.y = player.y + player.speed
    player.anim = player.animations.down
    isMoving = true
end 
    if love.keyboard.isDown("up")then 
    player.y = player.y - player.speed
    player.anim = player.animations.up
    isMoving = true
end 

    if isMoving == false then 
        player.anim:gotoFrame(2)
    end

     player.anim:update(dt)

     cam:lookAt(player.x, player.y)

     local w = love.graphics.getWidth()
     local h = love.graphics.getHeight()

     if cam.x < w/2 then 
        cam.x = w/2
     end

     if cam.y < h/2 then 
        cam.y = h/2
     end

     local mapW = gameMap.width *gameMap.tilewidth
     local mapH = gameMap.height * gameMap.tileheight


end

------Dialogue
function startDialogue()
    local storyDefinition = import("dialogue/suspect")
    story = Story(storyDefinition)

    dialogue.active = true
    dialogue.text = ""
    dialogue.choices = {}

    advanceDialogue()
end

function advanceDialogue()
    local textLines = {}

    while story:canContinue() do
        local line = story:Continue()
        table.insert(textLines, line)
    end

    dialogue.text = table.concat(textLines, "\n")

    dialogue.choices = {}

    local choices = story:currentChoices()

    for i, choice in ipairs(choices) do
        table.insert(dialogue.choices, {
            text = choice.text
        })
    end

    -- Close the dialogue if the story has ended
    if dialogue.text == "" and #dialogue.choices == 0 then
        dialogue.active = false
    end
end
    
function chooseOption(index)

    print("Selected choice:", index)
    print("Available choices:", #dialogue.choices)

    if dialogue.choices[index] then

        story:ChooseChoiceIndex(index)

        dialogue.text = ""
        dialogue.choices = {}

        advanceDialogue()
    end
end

function love.keypressed(key)

    if dialogue.active then

        local numkey = tonumber(key)

        -- Select a dialogue option
        if numkey and dialogue.choices[numkey] then
            chooseOption(numkey)

        -- Close dialogue when the story has ended
        elseif key == "space" or key == "return" then
            if #dialogue.choices == 0 then
                dialogue.active = false
            end
        end

        return
    end

    -- Start conversation with E
    if key == "e" then

        local dist = math.sqrt(
            (player.x - npc.x)^2 +
            (player.y - npc.y)^2
        )

        if dist < 50 then
            startDialogue()
        end
    end
end

function love.draw()
    cam:attach()
        gameMap:drawLayer(gameMap.layers["Tile Layer 1"])
        love.graphics.draw(player.spriteSheet, player.x, player.y, 0, 0.3, 0.3)
        npc.anim:draw(npc.spriteSheet, npc.x, npc.y, 0, 6, 6, 6, 9)
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 6, nil, 6, 9)
    cam:detach()

    local dist = math.sqrt((player.x - npc.x)^2 + (player.y - npc.y)^2)
    if dist < 50 and not dialogue.active then 
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Press [E] to Interrogate", 10, 10)
    end

   if dialogue.active then

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    local boxW = screenW - 40
    local boxH = math.min(260, screenH - 40)

    local boxX = 20
    local boxY = screenH - boxH - 20

    -- Background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle(
        "fill",
        boxX, boxY,
        boxW, boxH,
        8, 8
    )

    -- Border
    love.graphics.setColor(0.8, 0.7, 0.5, 1)
    love.graphics.rectangle(
        "line",
        boxX, boxY,
        boxW, boxH,
        8, 8
    )

    -- Dialogue text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        dialogue.text,
        boxX + 20,
        boxY + 20,
        boxW - 40,
        "left"
    )

    -- Choices
    love.graphics.setColor(0.9, 0.8, 0.3, 1)

    for i, choice in ipairs(dialogue.choices) do

        local choiceY = boxY + 120 + (i - 1) * 30

        love.graphics.printf(
            "[" .. i .. "] " .. choice.text,
            boxX + 20,
            choiceY,
            boxW - 40,
            "left"
        )
    end

    love.graphics.setColor(1, 1, 1, 1)

    end
end