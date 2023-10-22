
local modules = {}
modules.counter=require'counter'
local inst = {}

local wait = function()
  coroutine.yield() coroutine.yield()
end


inst.u_testbench = {
  param = {},
  io = {},
  co = coroutine.create(function(p, io)
    local clk      = {cur = 0}
    local reset_n  = {cur = 0}
    local en       = {cur = 0}
    local up       = {cur = 0}
    local cnt      = {cur = 0}
    local wrap_cnt = {cur = 5}

    -- ======================================================================================================
    -- INSTANTIATE DEVICE UNDER TEST (DUT)

    inst.u_counter_1 = {
      param = {
        WIDTH = 16
      },
      io = {
        clk      = clk,
        reset_n  = reset_n,
        en       = en,
        up       = up,
        wrap_cnt = wrap_cnt,
        cnt      = cnt
      },
      co = coroutine.create(modules.counter)
    } -- u_apb_ram_1

    -- ======================================================================================================
    -- MAIN TEST PROCESS

    print("Enable Up Counter")
    reset_n.cur = 1
    en.cur = 1
    up.cur = 1
    for i=1,10 do
      wait()
      print("counter should be incrementing = ", cnt.cur)
    end
    print("Disable Up Counter")
    en.cur = 0
    for i=1,10 do
      wait()
      print("counter should be fixed = ", cnt.cur)
    end
    print("Reset Counter")
    reset_n.cur = 0
    for i=1,10 do
      wait()
      print("counter should be 0 = ", cnt.cur)
    end

    print("Enable Down Counter")
    reset_n.cur = 1
    en.cur = 1
    up.cur = 0
    for i=1,10 do
      wait()
      print("counter should decrement = ", cnt.cur)
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

