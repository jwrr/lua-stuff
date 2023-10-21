
local co_t = {}

co_t.u_testbench = {
  io = {},
  sig = {
    test_done = false,
  },
  co = coroutine.create(function(p)
    local SIG = p.sig
    local reset_n     = {cur = 0}
    local en          = {cur = 0}
    local pclk        = {cur = 0}
    local preset_n    = {cur = 0}
    local paddr       = {cur = 0}
    local pwdata      = {cur = 0}
    local prdata      = {cur = 0}
    local pselx       = {cur = 0}
    local penable     = {cur = 0}
    local pwrite      = {cur = 0}
    local pready      = {cur = 1}
    local pslverr     = {cur = 0}


    -- ======================================================================================================

    co_t.u_apb_ram_1 = {
      io = {
        reset_n     = reset_n,
        pclk        = pclk,
        preset_n    = preset_n,
        paddr       = paddr,
        pwdata      = pwdata,
        prdata      = prdata,
        pselx       = pselx,
        penable     = penable,
        pwrite      = pwrite,
        pready      = pready,
        pslverr     = pslverr
      },
      co = coroutine.create(function(io)
        print("In u_apb_ram");
        local IO = io
        local apb_write = {cur=0}
        local apb_addr = {cur=0}
        local ram = {}
        for i=0,1023 do
          ram[i] = {cur=0,nxt=0}
        end
        
        while true do
          apb_addr.cur = IO.paddr.cur & 0x3ff or 0
          apb_write.cur =  IO.penable.cur==1 and IO.pselx.cur==1 and IO.pwrite.cur==1;
          if apb_write.cur then
            ram[apb_addr.cur].next = IO.pwdata.cur
          end
          coroutine.yield()
          IO.prdata.cur = ram[apb_addr.cur].next
          coroutine.yield()
        end
      end)
    } -- u_apb_ram_1

    
-- ======================================================================================================

    for k,v in pairs(co_t) do
      print(k,v)
    end
    reset_n.cur = 0
    coroutine.yield() coroutine.yield()
    reset_n.cur = 1
    coroutine.yield() coroutine.yield()
    en.cur = 1

    print("FILL RAM *************************************************************************************")
    penable.cur = 0
    pwrite.cur = 1
    pselx.cur = 1
    for i=0,1023 do
      paddr.cur = i
      pwdata.cur = i*i
      coroutine.yield() coroutine.yield()
      penable.cur = 1
      coroutine.yield() coroutine.yield()
      penable.cur = 0
      print("paddr", paddr.cur, "pwrite",  pwrite.cur, "prdata", prdata.cur)
    end

    print("READ RAM *************************************************************************************")
    penable.cur = 0
    pwrite.cur = 0
    pselx.cur = 1
    for i=0,1023 do
      paddr.cur = i
      coroutine.yield() coroutine.yield()
      penable.cur = 1
      coroutine.yield() coroutine.yield()
      penable.cur = 0
      print("paddr", paddr.cur, "pwrite",  pwrite.cur, "prdata", prdata.cur)
    end
    SIG.test_done = true
    print("TEST DONE")
    
  end)
}

  

--=====================================================================
--=====================================================================


print ("START SIMULATION")

for i=1,10000 do
  if co_t.u_testbench.sig.test_done then
    break
  end
--   print("EXEC")
  for k,v in pairs(co_t) do
    coroutine.resume(v.co, v.io)
  end
--   print("UPDATE")
  for k,v in pairs(co_t) do
    coroutine.resume(v.co, v.io)
  end
end


