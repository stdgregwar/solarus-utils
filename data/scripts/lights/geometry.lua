local vector = require('scripts/lights/Vector.lua')

local geometry = {}

-- segment = {origin:vector,extend:vector}
-- see ; https://stackoverflow.com/questions/563198/whats-the-most-efficent-way-to-calculate-where-two-line-segments-intersect
function geometry.segment_segment_intersect(a,b)
  local p = a.origin
  local r = a.extend
  local q = b.origin
  local s = b.extend
  local rxs = r:cross(s)
  local t = (q-p):cross(s/rxs)
  local u = (q-p):cross(r/rxs)
  --first case : collinear
  --TODO
  --second case : parralel
  if rxs == 0 and (q-p):cross(r) ~=0 then

  end
end

return geometry
