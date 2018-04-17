local ffi = require('ffi')

ffi.cdef[[
  typedef struct {uint8_t r, g, b, a;} rgba_pixel;
  ]]

local soft_surface = {}

function soft_surface:__index(k)
  return rawget(self,k) or soft_surface[k]
end

local function barycentric(triangle,x,y)
  local x1,x2,x3 = triangle[1].x,triangle[2].x,triangle[3].x
  local y1,y2,y3 = triangle[1].y,triangle[2].y,triangle[3].y
  local l1 = ((y2-y3)*(x-x3)+(x3-x2)*(y-y3))/((y2-y3)*(x1-x3)+(x3-x2)*(y1-y3))
  local l2 = ((y3-y1)*(x-x3)+(x1-x3)*(y-y3))/((y2-y3)*(x1-x3)+(x3-x2)*(y1-y3))
  local l3 = 1-l1-l2
  return l1,l2,l3
end

local function triangle_bounds(triangle,w,h)
  --since we work in screen space values are enough
  local min_x,max_x,min_y,max_y = w,0,h,0
  for i=1,3 do
    local x,y = triangle[i].x,triangle[i].y
    min_x = math.min(x,min_x)
    min_y = math.min(y,min_y)
    max_x = math.max(x,max_x)
    max_y = math.max(y,max_y)
  end
  return {min_x = min_x,min_y=min_y,max_x=max_x,max_y=max_y}
end

local function berp(v1,v2,v3,l1,l2,l3)
  return v1*l1+v2*l2+v3*l3
end

local function b_interp(l1,l2,l3,t)
  local vars = {'a','r','g','b'}
  local res = {}
  for _,v in ipairs(vars) do
    res[v] = berp(t[1][v] or 255,t[2][v] or 255 ,t[3][v] or 255,l1,l2,l3)
  end
  return res['r'],res['g'],res['b'],res['a']
end

function soft_surface:pixel(x,y)
  return self.pixels[x+y*self.width]
end

local function a_blend(da,sa,dc,sc)
  local da = da/256.0
  local sa = sa/256.0
  return (sa*sc+dc*da*(1-sa))/(sa+da*(1-sa))
end

function soft_surface:draw_triangle(triangle)
  local bounds = triangle_bounds(triangle,self.width,self.height)
  for x=bounds.min_x,bounds.max_x do
    for y=bounds.min_y,bounds.max_y do
      local l1,l2,l3 = barycentric(triangle,x,y)
      if l1 > 0 and l2 > 0 and l3 > 0 then
        local r,g,b,a = b_interp(l1,l2,l3,triangle)
        local pixel = self:pixel(x,y)
        pixel.r = a_blend(pixel.a,a,pixel.r,r)
        pixel.g = a_blend(pixel.a,a,pixel.g,g)
        pixel.b = a_blend(pixel.a,a,pixel.b,b)
        pixel.a = a + pixel.a*(1-a/256.0)
      end
    end
  end
  self.dirty = true
end

function soft_surface:fill(r,g,b,a)
  for i=0,self.width*self.height-1 do
    local p =self.pixels[i]
    p.r = r;
    p.a = a;
    p.g = g;
    p.b = b;
  end
  self.dirty = true
end

function soft_surface:flush_to_surf()
  if not self.dirty then return end
  local str = ffi.string(self.pixels,self.width*self.height*4)
  self.surface:set_pixels(str)
  self.dirty = false
end

function soft_surface:draw(sol_surface,x,y,w,h)
  self:flush_to_surf()
  self.surface:draw(sol_surface,x,y,w,h)
end

function soft_surface:new(width,height)
  local pixels = ffi.new('rgba_pixel[?]',width*height)
  local surface = sol.surface.create(width,height)
  return setmetatable({pixels=pixels,width=width,height=height,surface=surface},soft_surface)
end

return soft_surface
