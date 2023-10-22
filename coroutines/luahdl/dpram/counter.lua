
local counter = function(p, io)
  local WIDTH = p.WIDTH or 16
  local cnt = {cur=0,nxt=0}

  while true do
    -- EXEC
    local reset_n  = io.reset_n.cur
    local up       = io.up.cur
    local en       = io.en.cur
    local wrap_cnt = io.wrap_cnt.cur

    if reset_n == 0 then
      cnt.nxt= 0
    elseif en == 1 then
      if up == 1 then
        cnt.nxt = (cnt.cur < wrap_cnt) and cnt.cur + 1 or 0
      else
        cnt.nxt = (cnt.cur == 0) and wrap_cnt or cnt.cur - 1
      end
    end
    coroutine.yield()
    --UPDATE
    cnt.cur = cnt.nxt
    io.cnt.cur = cnt.cur
    coroutine.yield()
  end
end

return counter

