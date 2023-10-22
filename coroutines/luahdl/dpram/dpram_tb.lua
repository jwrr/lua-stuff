
local modules = {}
modules.dpram=require'dpram'
local inst = {}

local wait = function()
  coroutine.yield() coroutine.yield()
end


inst.u_testbench = {
  param = {},
  io = {},
  co = coroutine.create(function(p, io)
    local wclk   = {cur = 0}
    local write  = {cur = 0}
    local waddr  = {cur = 0}
    local wdata  = {cur = 0}
    local rclk   = {cur = 0}
    local raddr  = {cur = 0}
    local rdata  = {cur = 0}

    -- ======================================================================================================
    -- INSTANTIATE DEVICE UNDER TEST (DUT)

    inst.u_dpram_1 = {
      param = {
        DEPTH = 1024,
        WIDTH = 16
      },
      io = {
        wclk    = wclk,
        write   = write,
        waddr   = waddr,
        wdata   = wdata,
        rclk    = rclk,
        raddr   = raddr,
        rdata   = rdata
      },
      co = coroutine.create(modules.dpram)
    } -- u_apb_ram_1

    -- ======================================================================================================
    -- MAIN TEST PROCESS

    print("FILL RAM - Short Test")
    write.cur = 1
    for i=0,10 do
      waddr.cur = i
      wdata.cur = i*i
      wait() -- coroutine.yield() coroutine.yield()
      print("waddr", waddr.cur, "write",  write.cur, "rdata", rdata.cur)
    end
    print("READ RAM - Short Test")
    write.cur = 0
    for i=0,10 do
      raddr.cur = i
      wait() -- coroutine.yield() coroutine.yield()
      print("raddr", raddr.cur, "write",  write.cur, "rdata", rdata.cur)
    end

    print("FILL RAM - Long Test")
    write.cur = 1
    for i=0,1023 do
      waddr.cur = i
      wdata.cur = i*i
      wait() -- coroutine.yield() coroutine.yield()
      print("waddr", waddr.cur, "write",  write.cur, "rdata", rdata.cur)
    end
    print("READ RAM - Long Test")
    write.cur = 0
    for i=0,1023 do
      raddr.cur = i
      wait() -- coroutine.yield() coroutine.yield()
      print("raddr", raddr.cur, "write",  write.cur, "rdata", rdata.cur)
    end
    print("TEST DONE")
    
    lhdl.finish = true
  end)
}

local lhdl=require'lhdl'
lhdl.inst = inst
lhdl.modules = modules
lhdl.run()

return lhdl

