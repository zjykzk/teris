Class = function(prototype)
  local derived = {}
  local derivedTM = {
  	__index = prototype,

  	__call = function(proto, ...)
  	  local instance = {}

  	  local instanceMT = {
  	  	__index = derived,
        __call = function()
          print("WARNING! Attempt to invoke an instance of a class!")
          print(debug.traceback())
          return instance
        end,
      }
      setmetatable(instance, instanceMT)

      if (instance.__constructor) then
      	instance:__constructor(...)
      end

      return instance
    end,
  }
  setmetatable(derived, derivedTM)
  return derived
end

Point = Class()
function Point:__constructor(x, y)
  self.x_, self.y_ = x, y
end
function Point:x(x_)
  if x_ then self.x_ = x_ end
  return self.x_
end
function Point:y(y_)
  if y_ then self.y_ = y_ end
  return self.y_
end


Block = Class()
function Block:__constructor(name, rotateRange)
  self.name_ = name
  self.rotateRange_ = rotateRange
end
function Block:rotateRange()
  return self.rotateRange_.rotateRange
end
function Block:rotate()
  self.rotateRange_ = self.rotateRange_.next
end
function Block:points()
  r = self.rotateRange_.rotateRange
  return {r[1], r[2], r[3], r[4]}
end

function Block:tostring()
  local grid = {}
  max_row, max_column = 0, 0
  for _, p in ipairs(self:points()) do
  	local w = p:x() + 1
  	local h = p:y() + 1
  	grid[h] = grid[h] or {}
    local row = grid[h]
  	if h > max_row then max_row = h end
  	if w > max_column then max_column = w end
  	row[w] = 1
  end

  local str = "name:"..self.name_.."\n"
  for r = 1, max_row do
  	grid[r] = grid[r] or {}
    row = grid[r]
    if not grid[r] then
    	for c = 1, max_column do
        str = str.."o"
      end
    else
    	for c = 1, max_column do
    		if grid[r][c] then
          str = str.."x"
        else
        	str = str.."o"
        end
      end
    end
    str = str.."\n"
  end
  return str
end

--[[
the block rotate range, o - must be empty, # - ignore, x - the current block point:

left bottom is orginal point

  block
+-------------> x
|
|
| y

]]

--[[
oo##      ox##
xxxx      oxoo
#ooo      #xoo
#ooo      #xoo
]]

local l = {
	rotateRange = { Point(0, -3), Point(1, -3), Point(2, -3), Point(3, -3),
									Point(0, -4), Point(1, -4),
	                Point(1, -2), Point(2, -2), Point(3, -2),
	                Point(1, -1), Point(2, -1), Point(3, -1)
                }
}

l.next = {
	rotateRange = { Point(1, -1), Point(1, -2), Point(1, -3), Point(1, -4),
	                Point(0, -4), Point(0, -3),
	                Point(2, -1), Point(2, -3), Point(2, -2),
	                Point(3, -1), Point(3, -3), Point(3, -2)
                },
  next = l
}

--[[
oo###      ox###       
ooxxo      oxxoo
oxxoo      ooxoo
##o##      ##o##
]]

local s = {
	rotateRange = { Point(2, -3), Point(3, -3), Point(2, -2), Point(1, -2),
	                Point(0, -4), Point(0, -3), Point(0, -2),
	                Point(1, -4), Point(1, -3),
	                Point(3, -3), Point(2, -2), Point(3, -2),
	                Point(2, -1)
                }
}
s.next = {
	rotateRange = { Point(1, -4), Point(1, -3), Point(2, -3), Point(2, -2),
	                Point(0, -4), Point(0, -3), Point(0, -2), Point(2, -3),
	                Point(3, -3), Point(2, -2), Point(3, -2), Point(2, -1)
                },
  next = s
}

local blocks = {
	Block("I", l), Block("S", s)
}

function getOneBlock()
  return blocks[math.random(#blocks)]
end
