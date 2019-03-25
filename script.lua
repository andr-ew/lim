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

	pat = pattern_time.new()
	pat.process = function (e) end
	
	pat:clear()
	pat:rec_start()
	local e = {}
	e.id = 1
      e.x = 2
      e.y = 3
      e.state = 4
      pat:watch(e)
	pat:rec_stop()
	pat:start()
	pat:stop()
end