
local dpram = function(p, io)
  local DEPTH = p.DEPTH or 1024
  local WIDTH = p.WIDTH or 16
  local ram = {}
  for i=0,1023 do
    ram[i] = {cur=0,nxt=0}
  end

  while true do
    -- EXEC
    local write = io.write.cur
    local waddr = (io.waddr.cur < DEPTH) and io.waddr.cur or 0
    local wdata = io.wdata.cur & (2^WIDTH-1)
    local raddr = (io.raddr.cur < DEPTH) and io.raddr.cur or 0
    if write then
      ram[waddr].next = wdata
    end
    io.rdata.next = ram[raddr].cur
    coroutine.yield()
    --UPDATE
    ram[waddr].cur = ram[waddr].next
    io.rdata.cur = io.rdata.next
    coroutine.yield()
  end
end

return dpram
