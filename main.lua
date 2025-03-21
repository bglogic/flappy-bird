-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------


local gameStatus = {
  ready = 0,
  playing = 1,
  dying = 2,
  gameOver = 3
}
local currentGameStatus = gameStatus.ready

local yLand = display.actualContentHeight * 0.8
local xLand = display.contentCenterX

local yBird = display.contentCenterY - 50
local xBird = display.contentCenterX - 50

local wPipe = display.contentCenterX + 10
local yReady = display.contentCenterY - 140

local uBird = -200
local vBird = 0
local wBird = -320
local g = 800
local dt = 0.025

local score = 0
local bestScore = 0
local scoreStep = 5

local bird
local ground
local title
local getReady
local gameOver
local emitter

local board
local scoreTitle
local bestTitle
local silver
local gold

local pipes = {}

local dieSound
local hitSound
local pointSound
local swooshingSound
local wingSound
local boomSound

local function loadSounds()
  dieSound = audio.loadSound("Sounds/sfx_die.wav")
  hitSound = audio.loadSound("Sounds/sfx_hit.wav")
  pointSound = audio.loadSound("Sounds/sfx_point.wav")
  swooshingSound = audio.loadSound("Sounds/sfx_swooshing.wav")
  wingSound = audio.loadSound("Sounds/sfx_wing.wav")
  boomSound = audio.loadSound("Sounds/sfx_boom.mp3")
end


local function calcRandomHole()
  return 100 + 20 * math.random(10)
end

local function loadBestScore()
  local path = system.pathForFile("bestscore.txt", system.DocumentsDirectory)

  -- Open the file handle
  local file, errorString = io.open(path, "r")

  if not file then
    -- Error occurred; output the cause
    print("File error: " .. errorString)
  else
    -- Read data from file
    local contents = file:read("*a")
    -- Output the file contents
    bestScore = tonumber(contents) or 0
    -- Close the file handle
    io.close(file)
  end

  file = nil
end

local function saveBestScore()
  -- Path for the file to write
  local path = system.pathForFile("bestscore.txt", system.DocumentsDirectory)
  local file, errorString = io.open(path, "w")
  if not file then
    -- Error occurred; output the cause
    print("File error: " .. errorString)
  else
    file:write(bestScore)
    io.close(file)
  end
  file = nil
end


local function setupBird()
  local imageSheet = graphics.newImageSheet("Assets/bird.png", {
    width = 70,
    height = 50,
    numFrames = 4,
    sheetContentWidth = 280, -- width of original 1x size of entire sheet
    sheetContentHeight = 50  -- height of original 1x size of entire sheet
  })

  bird = display.newSprite(imageSheet, {
    name = "walking",
    start = 1,
    count = 3,
    time = 300,
    loopCount = 2,            -- Optional ; default is 0 (loop indefinitely)
    loopDirection = "forward" -- Optional ; values include "forward" or "bounce"
  })
  bird.x = xBird
  bird.y = yBird
end

local function initGame()
  score = 0
  scoreStep = 5
  title.text = score

  for i = 1, 3 do
    pipes[i].x = 400 + display.contentCenterX * (i - 1)
    pipes[i].y = calcRandomHole()
  end
  yBird = display.contentCenterY - 50
  xBird = display.contentCenterX - 50
  getReady.y = 0
  getReady.alpha = 1
  gameOver.y = 0
  gameOver.alpha = 0
  board.y = 0
  board.alpha = 0
  audio.play(swooshingSound)
  transition.to(bird, { time = 300, x = xBird, y = yBird, rotation = 0 })
  transition.to(getReady, {
    time = 600,
    y = yReady,
    transition = easing.outBounce,
    onComplete = function() bird:play() end
  })
end

local function flap()
  if currentGameStatus == gameStatus.ready then
    currentGameStatus = gameStatus.playing
    getReady.alpha = 0
  end

  if currentGameStatus == gameStatus.playing then
    vBird = wBird
    bird:play()
    audio.play(wingSound)
  end

  if currentGameStatus == gameStatus.gameOver then
    currentGameStatus = gameStatus.ready
    initGame()
  end
end

local function tapInput()
  flap()
  return true -- Prevents propagation to underlying objects
end

local function keyInput(event)
  if (event.keyName == "up") then
    local phase = event.phase
    if (phase == "down") then
      flap()
    end
  end

  return true -- Prevents propagation to underlying objects
end

local function setupExplosion()
  local dx = 31
  local p = "Assets/habra.png"
  local emitterParams = {
    startParticleSizeVariance = dx / 2,
    startColorAlpha = 0.61,
    startColorGreen = 0.3031555,
    startColorRed = 0.08373094,
    yCoordFlipped = 0,
    blendFuncSource = 770,
    blendFuncDestination = 1,
    rotatePerSecondVariance = 153.95,
    particleLifespan = 0.7237,
    tangentialAcceleration = -144.74,
    startParticleSize = dx,
    textureFileName = p,
    startColorVarianceAlpha = 1,
    maxParticles = 128,
    finishParticleSize = dx / 3,
    duration = 0.75,
    finishColorRed = 0.078,
    finishColorAlpha = 0.75,
    finishColorBlue = 0.3699196,
    finishColorGreen = 0.5443883,
    maxRadiusVariance = 172.63,
    finishParticleSizeVariance = dx / 2,
    gravityy = 220.0,
    speedVariance = 258.79,
    tangentialAccelVariance = -92.11,
    angleVariance = -300.0,
    angle = -900.11
  }
  emitter = display.newEmitter(emitterParams)
  emitter:stop()
end


local function explosion()
  emitter.x = bird.x
  emitter.y = bird.y
  emitter:start()
end




local function crash()
  currentGameStatus = gameStatus.gameOver
  audio.play(hitSound)
  gameOver.y = 0
  gameOver.alpha = 1
  transition.to(gameOver, { time = 600, y = yReady, transition = easing.outBounce })
  board.y = 0
  board.alpha = 1

  if score > bestScore then
    bestScore = score
    saveBestScore()
  end
  bestTitle.text = bestScore
  scoreTitle.text = score
  if score < 10 then
    silver.alpha = 0
    gold.alpha = 0
  elseif score < 50 then
    silver.alpha = 1
    gold.alpha = 0
  else
    silver.alpha = 0
    gold.alpha = 1
  end
  transition.to(board, { time = 600, y = yReady + 100, transition = easing.outBounce })
end

local function collision(i)
  local dx = 40 -- horizontal space of hole
  local dy = 50 -- vertical space of hole
  local boom = 0
  local x = pipes[i].x
  local y = pipes[i].y

  if xBird > (x - dx) and xBird < (x + dx) then
    if yBird > (y + dy) or yBird < (y - dy) then
      boom = 1
    end
  end
  return boom
end

local function gameLoop()
  local eps = 10
  local leftEdge = -60
  if currentGameStatus == gameStatus.playing then
    xLand = xLand + dt * uBird
    if xLand < 0 then
      xLand = display.contentCenterX * 2 + xLand
    end
    ground.x = xLand
    for i = 1, 3 do
      local xb = xBird - eps
      local xOld = pipes[i].x
      local x = xOld + dt * uBird
      if x < leftEdge then
        x = wPipe * 3 + x
        pipes[i].y = calcRandomHole()
      end
      if xOld > xb and x <= xb then
        score = score + 1
        title.text = score
        if score == scoreStep then
          scoreStep = scoreStep + 5
          audio.play(pointSound)
        end
      end
      pipes[i].x = x
      if collision(i) == 1 then
        explosion()
        audio.play(dieSound)
        currentGameStatus = gameStatus.dying
      end
    end
  end

  if currentGameStatus == gameStatus.playing or currentGameStatus == gameStatus.dying then
    vBird = vBird + dt * g
    yBird = yBird + dt * vBird
    if yBird > yLand - eps then
      yBird = yLand - eps
      crash()
    end
    bird.x = xBird
    bird.y = yBird
    if currentGameStatus == gameStatus.playing then
      bird.rotation = -30 * math.atan(vBird / uBird)
    else
      bird.rotation = vBird / 8
    end
  end
end

local function setupLand()
  ground = display.newImageRect("Assets/land.png", display.actualContentWidth * 2, display.actualContentHeight * 0.2)
  ground.x = display.contentCenterX
  ground.y = display.actualContentHeight * 0.9
end

local function setupImages()
  local background = display.newImageRect(
    "Assets/background.png",
    display.actualContentWidth,
    display.actualContentHeight
  )
  background.x = display.contentCenterX
  background.y = display.contentCenterY

  for i = 1, 3 do
    pipes[i] = display.newImageRect("Assets/pipe.png", 80, 1000)
    pipes[i].x = 440 + wPipe * (i - 1)
    pipes[i].y = calcRandomHole()
  end

  getReady = display.newImageRect("Assets/getready.png", 200, 60)
  getReady.x = display.contentCenterX
  getReady.y = yReady
  getReady.alpha = 0

  gameOver = display.newImageRect("Assets/gameover.png", 200, 60)
  gameOver.x = display.contentCenterX
  gameOver.y = 0
  gameOver.alpha = 0

  board = display.newGroup()
  local img = display.newImageRect(board, "Assets/board.png", 240, 140)

  scoreTitle = display.newText({
    parent = board,
    text = tostring(score) or "0",
    x = 80,
    y = -18,
    font = "Assets/troika.otf",
    fontSize = 21
  })
  scoreTitle:setFillColor(0.75, 0, 0)

  bestTitle = display.newText({
    parent = board,
    text = tostring(bestScore) or "0",
    x = 80,
    y = 24,
    font = "Assets/troika.otf",
    fontSize = 21
  })
  bestTitle:setFillColor(0.75, 0, 0)

  silver = display.newImageRect(board, "Assets/silver.png", 44, 44)
  silver.x = -64
  silver.y = 4

  gold = display.newImageRect(board, "Assets/gold.png", 44, 44)
  gold.x = -64
  gold.y = 4

  board.x = display.contentCenterX
  board.y = 0
  board.alpha = 0

  title = display.newText({
    x = display.contentCenterX,
    y = 60,
    text = "",
    font = "Assets/troika.otf",
    fontSize = 35
  })
  title:setFillColor(1, 1, 1)
end

-- Start application point
loadSounds()
setupImages()
setupBird()
setupExplosion()
setupLand()
initGame()
loadBestScore()
local gameLoopTimer = timer.performWithDelay(25, gameLoop, 0)

Runtime:addEventListener("tap", tapInput)
Runtime:addEventListener("key", keyInput)

display.setStatusBar(display.HiddenStatusBar)
