this.inlets = 1
this.outlets = 1

max_free = true

norns = {}
norns.metro = function (...) end
norns.version = { metro = "" }
norns.midi = {}
norns.menu_midi_event = function (...) end

output = function (...)
    outlet(0, "out", unpack(arg))
end

function require (file)
    if file == "norns" then
        return norns
    else
        return dofile(this.path .. "/lib/" .. file .. ".lua")
    end
end

function loadbang ()
	init()
end

function get_time ()
    local s = os.clock() * 10
    local f = math.floor(s)
    print(f, (s - f) * 1000000)
    return f, (s - f) * 1000000
end

util = require 'util'
tab = require 'tabutil'
controlspec = require 'controlspec'

--BITWISE-----------------------------------------------------------------------

--[[

jit.gl.lua runs Lua 5.1, meaning that the bitwise operators from 5.3 on norns are missing. use these instead: 

    bit32.arshift (x, disp) --> z
    bit32.band (...) --> z
    bit32.bnot (x) --> z
    bit32.bor (...) --> z
    bit32.btest (...) --> true | false
    bit32.bxor (...) --> z
    bit32.extract (x, field [, width]) --> z
    bit32.replace (x, v, field [, width]) --> z
    bit32.lrotate (x, disp) --> z
    bit32.lshift (x, disp) --> z
    bit32.rrotate (x, disp) --> z
    bit32.rshift (x, disp) --> z

]]--

bit32 = require 'numberlua'.bit32

--MIDI-------------------------------------------------------------------------

function midi_to_max (...)
    outlet(0, "out", "midi", ...)
end

function midi_send (dev, d)
    if dev == "max" then midi_to_max(d) end
end

--print("thing", 0xf0 & 1)

midi = require 'midi.5.1'

--function midi_from_max (data)
--    if max_free then
--        max_free = false
--        max_free = true
--    end
--end

norns.midi.add(74, "max", "max")


--METRO------------------------------------------------------------------------

function metro_start (id, time, count, init_stage)
    metro_to_max("metro_start", id, time, count, init_stage)
end

function metro_stop (id)
    metro_to_max("metro_stop", id)
end

function metro_set_time (id, time)
    metro_to_max("metro_set_time", id, time)
end

function metro_to_max (...)
    outlet(0, "metro", ...)
end

--function metro_from_max (idx, stage)
--    if max_free then
--        max_free = false
--        norns.metro(idx, stage)
--        max_free = true
--    end
--end

metro = require 'metro'

--ENGINE/HARDWARE-------------------------------------------------------------

engine = {}
engine.name = "ronald xavier"

setmetatable(engine, engine)

function engine.__index(self, command)
    return function (...)
        output(command, unpack(arg))
    end
end

screen = {}

setmetatable(screen, screen)

function screen.__index(self, command)
    return function (...)
        --output(command, unpack(arg))
    end
end

mix = {}

setmetatable(mix, mix)

function mix.__index(self, command)
    return function (...)
        output(command, unpack(arg))
    end
end

file = {}

setmetatable(file, file)

function file.__index(self, command)
    return function (...)
        output(command, unpack(arg))
    end
end

--PARAMS-----------------------------------------------------------------------

paramset = require 'paramset'

params = paramset.new()

--function param_from_max (index, v)
--    if max_free then
--        max_free = false
--        params:set(index, v)
--        max_free = true
--    end
--end

--GRID-------------------------------------------------------------------------

monome_instance = nil

grid = {
	connect = function ()
		monome_instance = Grid:new()

		return monome_instance
	end
}

mute = function (i)
    if monome_instance then
        monome_instance:mute(i)
    end
end

disconnect = function ()
    if monome_instance then
        monome_instance:disconnect()
    end
end

reconnect = function ()
    if monome_instance then
        monome_instance:reconnect()
    end
end

focus = function (i)
    if monome_instance then
        monome_instance:focus(i)
    end
end

--grid_input = function (...)
--    local grid_inputs = {
--        monome = {
--            osc = function (n)
--                if monome_instance then
--                    monome_instance:osc(n)
--                end
--            end,
--            menu = function (n)
--                if monome_instance then
--                    monome_instance:menu(n)
--                end
--            end
--        }
--    }
--    
--    print(...)
--    
--    local n = {}
--    for i,v in ipairs(arg) do
--        if i>2 then
--            n[i-2] = v
--        end
--    end
--    
--    grid_inputs[arg[1]][arg[2]](n)
--end

--function monome_from_max (source, ...)
--    if max_free then
--        max_free = false
--
--        if(source == "menu") then
--            monome_instance:menu(unpack(arg))
--        elseif (source == "osc") then
--            monome_instance:osc(unpack(arg))
--        end
--        
--        max_free = true
--    end
--end

Monome = {
    prefix = "",
    connected = 0,
    device = 0,
    index = 1,
    enabled = 1,
    device_size,
    serials = {},
    devices = {},
    ports = {},
    in_port = math.random(1000) + 12288,
    prefix = "/monome",
    autoconnect = 1
}

function Monome:new (o, f)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    outlet(0, "monome", 0, "port", self.in_port)
    self:rescan()
    
    if f ~= nil then f() end
    
    return o
end

function Monome:send (n)
    if self.enabled then
        --print("send", unpack(n))
        
        outlet(0, "monome", 2, unpack(n))
    end
end

function Monome:rescan ()
    if self.enabled then
        outlet(0, "monome", 1, "/serialosc/list", "localhost", self.in_port)
		outlet(0, "monome", 1, "/serialosc/notify", "localhost", self.in_port)
		outlet(0, "monome", 3, "clear")
		outlet(0, "monome", 3, "append", "none")
		outlet(0, "monome", 3, "textcolor", 1.0, 1.0, 1.0, 0.3)
		
		self.ports = {}
		self.devices = {}
		self.serials = {}
    end
end

function Monome:osc (...)
    --print(n[1], n[2], n[3])
    if arg[1] == "/serialosc/device" then
        outlet(0, "monome", 3, "append", arg[2], arg[3])
		self.ports[#self.ports + 1] = arg[4]
		self.devices[#self.devices + 1] = arg[3]
		self.serials[#self.serials + 1] = arg[2]
        
        if self.autoconnect == 1 and self.enabled then
            outlet(0, "monome", 3, 1)
        end
        
        if self.connected and self.enabled then
            local i
            
            for i,v in ipairs(self.serials) do
                if v == self.connected then
                    outlet(0, "monome", 3, i+1)
                end
            end
        end
    elseif arg[1] == "/serialosc/remove" or arg[1] == "/serialosc/add" then
        if self.enabled then self:rescan() end
    elseif arg[1] == "/sys/port" and arg[2] ~= self.in_port then
        outlet(0, "monome", 3, "set", 0)
		outlet(0, "monome", 3, "textcolor", 1.0, 1.0, 1.0, 0.3)
		self.connected = 0
		self.device = 0
    elseif arg[1] == "/sys/size" then
        self.device_size = {}
		self.device_size[1] = arg[2]
		self.device_size[2] = arg[3]
    else
        if self.enabled and self.parse ~= nil then self:parse(unpack(arg)) end
    end
end

function Monome:menu (i, ...)
    if self.enabled then
        if i ~= 0 then
            self.index = i
            
            outlet(0, "monome", 3, "textcolor", 1.0, 1.0, 1.0, 1.0)
			outlet(0, "monome", 2, "port", self.ports[self.index])
			outlet(0, "monome", 2, "/sys/port", self.in_port)
			outlet(0, "monome", 2, "/sys/prefix", self.prefix)
			outlet(0, "monome", 2, "/sys/info")
			
			outlet(0, "monome", 4, self.serials[self.index])
			outlet(0, "monome", 5, self.devices[self.index])
                
            self.connected = self.serials[self.index];
			self.device = self.devices[self.index];
			
			self:onreconnect();
        else
            self:ondisconnect()
			
			if self.connected then 
                outlet(0, "monome", 2, "/sys/port", 0)
            end
        end
    end
end
        
function Monome:ondisconnect () end
        
function Monome:onreconnect () end
        
function Monome:disconnect ()
    self:ondisconnect()
    outlet(0, "monome", 3, 0)
end
        
function Monome:reconnect ()
    outlet(0, "monome", 3, self.index)
    self:onreconnect()
end

--function Monome:parse (n) end
        
function Monome:mute (i)
    self.enabled = not i
    
    outlet(0, "monome", 3, "ignoreclick", i)
            
    if i then
        outlet(0, "monome", 3, "textcolor", 1.0, 1.0, 1.0, 0.3)
    else
        outlet(0, "monome", 3, "textcolor", 1.0, 1.0, 1.0, 1.0)
    end
end

function Monome:focus (i)
    if i then
        self:mute(0)
        self:reconnect()
    else
        self:disconnect()
        self:mute(1)
    end
end

mtrx = {}
for x=1, 16 do
    mtrx[x] = {}

    for y=1, 16 do
        mtrx[x][y] = 0
    end
end

Grid = Monome:new({
                matrix = mtrx,
                quad_off = {{0, 0,}, {8, 0}, {0, 8}, {8, 8}, {16, 0,}, {24, 0}, {16, 8}, {24, 8}},
                quad_count = nil,
                key = function (x, y, z) end
            }
        )

function Grid:all (z)
    for x=1, 16 do
        self.matrix[x] = {}
        
        for y=1, 16 do
            self.matrix[x][y] = z --attempt to concatenate a function value ??
        end
    end
end
        
function Grid:led (x, y, z)
    self.matrix[x][y] = z
end
        
function Grid:refresh ()
    if self.device_size ~= nil then
        
        self.quad_count = self.device_size[1] * self.device_size[2] / 64
                
        for i=1, self.quad_count do
            quad_mess =  { 
                        self.prefix .. "/grid/led/level/map", self.quad_off[i][1], self.quad_off[i][2] 
                    }
                    
            for y=0, 7 do
                for x=0, 7 do
                    --print(self.matrix[x + self.quad_off[i][1]][y + self.quad_off[i][2]])
                    
                    quad_mess[(y * 8) + x + 4] = self.matrix[x + 1 + self.quad_off[i][1]][y + 1 + self.quad_off[i][2]]
                end
            end
            
            --print(unpack(quad_mess))        
            self:send(quad_mess)
        end
    else
        --run this function again in 1ms ?
    end
end
        
function Grid:ondisconnect ()
    self:send({ self.prefix .. "/grid/led/level/all", 0 })
end
        
function Grid:onreconnect ()
    self:refresh()
end
        
function Grid:mute (i)
    if i then
        self:ondisconnect()
        Monome.mute(self, i)
    else
        Monome.mute(self, i)
        self:onreconnect()
    end
end

function Grid:parse (...)
    if arg[1] == "/monome/grid/key" and self.key ~= nil and arg.n == 4 then
        --print(arg[2] + 1, arg[3] + 1, arg[4])
        self.key(arg[2] + 1, arg[3] + 1, arg[4])
    end
end

--INPUT------------------------------------------------------------------------

function from_max (i, ...)
--        print(i, unpack(arg))
    local inputs = {
        norns.metro,
        function (...) norns.midi.event(74, unpack(arg)) end,
        function (...) monome_instance:osc(unpack(arg)) end,
        function (...) monome_instance:menu(unpack(arg)) end,
        function (...) params:set(unpack(arg)) end
    }
    
    inputs[i + 1](unpack(arg))
end