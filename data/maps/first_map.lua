-- Lua script of map first_map.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()
local hero = map:get_hero()

local light_mgr = require('scripts/lights/light_manager')

local tunic = hero:get_sprite('tunic')

--light_mgr:add_occluder(hero,tunic)

local def_mask = sol.surface.create(sol.video.get_quest_size())
local compose = sol.surface.create(sol.video.get_quest_size())

local dist_s = sol.shader.create('distort')
def_mask:set_shader(dist_s)
dist_s:set_uniform('distort_factor',0.01)
dist_s:set_uniform('diffuse',compose)

-- Event called at initialization time, as soon as this map becomes is loaded.
function map:on_started()
  -- You can initialize the movement and sprites of various
  -- map entities here.
end

local offsets = {[0]={8,-8},[1]={0,-24},[2]={-8,-8},[3]={0,16}}

function hero:on_position_changed(x,y,l)
  local dir = tunic:get_direction()
  local of = {0,0}--offsets[dir]
  light1:set_position(x+of[1],y+of[2],l)
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end


function map:on_draw(dst)
  light_mgr:draw(dst,self)
  def_mask:clear()
  for l in map:get_entities('light') do
    l:draw_disturb(def_mask)
  end
  dst:draw(compose,0,0)
  def_mask:draw(dst,0,0)
end
