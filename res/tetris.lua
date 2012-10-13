package.path = package.path..";./res/?.lua"
require 'conf'
require 'block'

local width,height = window.width,window.height
local State = {
  STOP = 0,
  RUNING = 1,
  PAUSE = 2
}

tetris = {
  Rotate = 0, Down = 1, Left = 2, Right = 3,
  grid = {},
  state = State.RUNING,
  block = nil,
  orgLoc = Point(width / 2, 1)
}

local function isValidPoint(x, y)
	return x >=1 and x <= width and y >=1 and y <= height
end

local function canDoAction(points, x, y, grid)
  for _, p in ipairs(points) do
    local tx, ty = x + p:x(), y + p:y()
    print("check wheather can do action", tx, ty)
    if tx < 1 or tx > width then return false end
    if isValidPoint(tx, ty) and grid[ty][tx] == 1 then
    	return false
    end
  end
  return true
end

local function showGrid(grid)
	str = ""
	for r = 1, height do
		for c = 1, width do
			if grid[r][c] == 1 then str = str.."x" else str = str.."o" end
		end
		str = str.."\n"
	end
	print(str)
end

local function markGrid(points, x, y, grid)
  for _, p in ipairs(points) do
  	local x, y = p:x() + x, p:y() + y
  	if isValidPoint(x, y) then
			grid[y][x] = 1
		end
  end
end

local function unmarkGrid(points, x, y, grid)
  for _, p in ipairs(points) do
  	local x, y = p:x() + x, p:y() + y
  	if isValidPoint(x, y) then
			grid[y][x] = 0
		end
  end
end

local function eraseCanvas(points, orgX, orgY)
  for _, p in ipairs(points) do
  	local x, y = p:x() + orgX, p:y() + orgY 
  	if isValidPoint(x, y) then
			Canvas.delRect(x, y)
		end
	end
end

local function drawCanvas(points, newX, newY, grid)
  for _, p in ipairs(points) do
  	x, y = p:x() + newX, p:y() + newY
  	if isValidPoint(x, y) then
			grid[y][x] = 1
			 Canvas.drawRect(x, y)
		end
  end
  showGrid(grid)
end

local function isBlockStop(points, orgx, orgy, grid)
  for _, p in ipairs(points) do
  	x, y = p:x() + orgx, p:y() + 1 + orgy
  	print("is block stop", x, y)
  	if isValidPoint(x, y) and grid[y][x] == 1 or y > height then
  		print("block stops", x, y)
  		return true end
  end
  return false
end

local function isGameOver(points, x, y)
  for _, p in ipairs(points) do
    if p:y() + y < 0 then return true end
  end
  return false
end

tetris.move = function (action)
	print(tetris.state)
  if tetris.state ~= State.RUNING then return end
  local block = tetris.block
  print("block : "..block:tostring())
	local x, y = tetris.orgLoc:x(), tetris.orgLoc:y()
	print("orginate point ", x, y)
	local points = block:points()
	local grid = tetris.grid
	unmarkGrid(points, x, y, grid)
  if isBlockStop(points, x, y, grid) then
    if isGameOver(points, x, y) then
      over()
      print("game over")
      return
    end
    markGrid(points, x, y, grid)
    tetris.block = getOneBlock()
    tetris.orgLoc:x(width / 2)
    tetris.orgLoc:y(1)
    return
  end

	local orgLoc = tetris.orgLoc
  if action == tetris.Rotate then 
  	local oldPoints = points
    if canDoAction(block:rotateRange(), x, y, grid) then
      block:rotate()
      points = block:points()
    else orgLoc:y(y + 1) end
    eraseCanvas(oldPoints, x, y)
    drawCanvas(points, x, orgLoc:y(), grid)
    tetris.move()
    return
  end

  if action == tetris.Left and canDoAction(points, x - 1, y, grid) then
  	orgLoc:x(x - 1)
    eraseCanvas(points, x, y)
    drawCanvas(points, orgLoc:x(), y, grid)
    tetris.move()
    return
	end

  if action == tetris.Right and canDoAction(points, x + 1, y, grid) then
  	orgLoc:x(x + 1)
    eraseCanvas(points, x, y)
    drawCanvas(points, orgLoc:x(), y, grid)
    tetris.move()
    return
  end

  if action == tetris.Down and canDoAction(points, x, y + 1, grid) then
		orgLoc:y(y + 1)
    eraseCanvas(points, x, y)
    drawCanvas(points, x, orgLoc:y(), grid)
    tetris.move()
    return
	end

	if canDoAction(points, x, y + 1, grid) then
		orgLoc:y(y + 1)
    eraseCanvas(points, x, y)
    drawCanvas(points, x, orgLoc:y(), grid)
	end
	print("after")
end

function start()
  tetris.state = State.RUNING
  block = getOneBlock()
end

function over()
  tetris.state = State.STOP
  Canvas.over()
end

function pause()
  tetris.state = State.PAUSE
end

function continue()
  tetris.state = State.RUNING
end

local function init()
  for h = 1, height do
    tetris.grid[h] = tetris.grid[h] or {}
    for w = 1, width do
      tetris.grid[h][w] = 0
    end
  end
  tetris.block = getOneBlock()
  print(tetris.block:tostring())
end

init()
