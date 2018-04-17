-- Lua script of custom entity light.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local light_mgr = require('scripts/lights/light_manager')

local radius = tonumber(entity:get_property('radius')) or 120
local size = radius*2
local color_str = entity:get_property('color') or '255,255,255'
local color = {color_str:match('(%d+),(%d+),(%d+)')}
for i,k in ipairs(color) do
  color[i] = k/256.0
end

entity:set_can_traverse(true)

local angular_resolution = 256
local make_shadow_s = sol.shader.create('make_shadow1d')
local cast_shadow_s = sol.shader.create('cast_shadow1d')
local fire_dist = sol.shader.create('fire_dist')
local occ_map = sol.surface.create(size,size)
occ_map:set_shader(make_shadow_s)
local shad_map = sol.surface.create(angular_resolution,1)
shad_map:set_shader(cast_shadow_s)
shad_map:set_blend_mode('add')

make_shadow_s:set_uniform('resolution',{radius,radius})
cast_shadow_s:set_uniform('scale',{(size*1.0)/angular_resolution,size})
cast_shadow_s:set_uniform('resolution',{radius,radius})
cast_shadow_s:set_uniform('lcolor',color)


local plasma = sol.surface.create('entities/plasma.png')
local fire_sprite = entity:get_sprite()
entity:remove_sprite(fire_sprite)
fire_dist:set_uniform('plasma',plasma)
fire_sprite:set_shader(fire_dist)
--fire_sprite:set_blend_mode('add')
-- Event called when the custom entity is initialized.
function entity:on_created()

  -- Initialize the properties of your custom entity here,
  -- like the sprite, the size, and whether it can traverse other
  -- entities and be traversed by them.
  light_mgr:add_light(self,entity:get_name())
end

function entity:draw_visual(dst,drawable,x,y)
  local cx,cy = map:get_camera():get_position()
  drawable:draw(dst,x-cx,y-cy)
end

function entity:draw_light(dst,occluders)
  local cx,cy = map:get_camera():get_position()
  local lx,ly = entity:get_position()
  local lw,lh = entity:get_size()
  --make lx,ly the position of the light influence quad
  lx,ly = lx-radius,ly-radius

  --draw occluders on occluder map
  occ_map:clear()
  for ent,occ in pairs(occluders) do
    local ex,ey = ent:get_position()
    local x,y = ex-lx,ey-ly
    occ:draw(occ_map,x,y)
  end

  --compute 1D shadow map
  occ_map:draw(shad_map,0,0)
  
  --draw 1D shadow as additive shadows
  self:draw_visual(dst,shad_map, lx,ly)
end

function entity:draw_disturb(dst)
  self:draw_visual(dst,fire_sprite,self:get_position())
end
