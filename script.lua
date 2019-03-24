---[[
dofile(this.path.."/lim.lua")

local pattern_time = require 'pattern_time'

engine.name = 'scooby doo'

g = grid.connect()

g.key = function (x, y, z)
	if z == 1 then
		g:led(x, y, (g.matrix[x][y] == 0 and 1 or 0) * 11)
		g:refresh()
		
		engine.foo(x, y)
		screen.line_width(1)
	end
end

function init ()
	m = midi.connect()
  	m.event = function(data) m:send(data) end

	params:add_control("shape", "shape", controlspec.new(0,1,"lin",0,0,""))
	params:set_action("shape", function(x) engine.shape(x) end)

	met = metro.alloc(function() print "event" end,1,3)
	met.time = 1000
	met:start()
end