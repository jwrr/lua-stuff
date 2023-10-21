
local top = {}

top.u_testbench = {
  sig = {
    test_done   = false,
    reset_n     = {cur = 0},
    en          = {cur = 0},
    pclk        = {cur = 0},
    preset_n    = {cur = 0},
    paddr       = {cur = 0},
    pwdata      = {cur = 0},
    prdata      = {cur = 0},
    pselx       = {cur = 0},
    penable     = {cur = 0},
    pwrite      = {cur = 0},
    pready      = {cur = 1},
    pslverr     = {cur = 0}
  },
  co = coroutine.create(function(p)
    local SIG = p.sig
    SIG.reset_n.cur = 0
    coroutine.yield() coroutine.yield()
    SIG.reset_n.cur = 1
    coroutine.yield() coroutine.yield()
    SIG.en.cur = 1

    print("FILL RAM *************************************************************************************")
    SIG.penable.cur = 0
    SIG.pwrite.cur = 1
    SIG.pselx.cur = 1
    for i=0,20 do
      SIG.paddr.cur = i
      SIG.pwdata.cur = i*i
      coroutine.yield() coroutine.yield()
      SIG.penable.cur = 1
      coroutine.yield() coroutine.yield()
      SIG.penable.cur = 0
    end

    print("READ RAM *************************************************************************************")
    SIG.penable.cur = 0
    SIG.pwrite.cur = 0
    SIG.pselx.cur = 1
    for i=0,20 do
      SIG.paddr.cur = i
      coroutine.yield() coroutine.yield()
      SIG.penable.cur = 1
      coroutine.yield() coroutine.yield()
      SIG.penable.cur = 0
      print("paddr", SIG.paddr.cur, "pwrite",  SIG.pwrite.cur, "prdata", SIG.prdata.cur,  "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
    end
    SIG.test_done = true
    print("TEST DONE")
    
  end)
}

  
top.u_apb_ram = {
  interface = {
    reset_n     = top.u_testbench.sig.reset_n,
    pclk        = top.u_testbench.sig.pclk,
    preset_n    = top.u_testbench.sig.preset_n,
    paddr       = top.u_testbench.sig.paddr,
    pwdata      = top.u_testbench.sig.pwdata,
    prdata      = top.u_testbench.sig.prdata,
    pselx       = top.u_testbench.sig.pselx,
    penable     = top.u_testbench.sig.penable,
    pwrite      = top.u_testbench.sig.pwrite,
    pready      = top.u_testbench.sig.pready,
    pslverr     = top.u_testbench.sig.pslverr
  },
  co = coroutine.create(function(p)
    local IO = p.interface
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
}



top.u_counter1 = {
  interface = {
    reset_n = top.u_testbench.sig.reset_n,
    en      = top.u_testbench.sig.en,
    step_size = {cur = 1, nxt = 1},
    cnt = {cur = 0, nxt = 0}
  },
  sig = {
  },
  co = coroutine.create(function(p)
    local IO = p.interface
    local S = p.sig
    while true do
      if IO.reset_n.cur == 1 then
        if IO.en.cur == 1 then
          IO.cnt.nxt = IO.cnt.cur + IO.step_size.cur
        end
      else
        IO.cnt.nxt = 0
      end
      coroutine.yield()
      IO.cnt.cur = IO.cnt.nxt
      print("in u_counter1. cnt = ", IO.cnt.cur)
      coroutine.yield()
    end
  end)
}



top.u_counter2 = {
  interface = {
    reset_n = top.u_testbench,
    step_size = {cur=2},
    cnt = {cur = 0, nxt = 0}
  },
  signala = {
  },
  co = coroutine.create(function(p)
    local IO = p.interface
    local S = p.sig
    while true do
      IO.cnt.nxt = IO.cnt.cur + IO.step_size.cur
      coroutine.yield()
      IO.cnt.cur = IO.cnt.nxt
      print("in u_counter2. cnt = ", IO.cnt.cur)
      coroutine.yield()
    end
  end)
}



top.u_adder = {
  interface = {
    reset_n = top.u_testbench,
    a = top.u_counter1.interface.cnt,
    b = top.u_counter2.interface.cnt,
    sum = {cur = 0, nxt = 0}
  },
  sig = {
  },
  co = coroutine.create(function(p)
    local IO = p.interface
    local S = p.sig
    while true do
      IO.sum.nxt = IO.a.cur + IO.b.cur
      coroutine.yield()
      IO.sum.cur = IO.sum.nxt
      print("in u_adder. sum = ", IO.sum.cur)
      coroutine.yield()
    end
  end)
}


--=====================================================================
--=====================================================================


print ("START SIMULATION")

for i=1,10000 do
  if top.u_testbench.sig.test_done then
    break
  end
  print("EXEC")
  for k,v in pairs(top) do
    coroutine.resume(v.co, v)
  end
  print("UPDATE")
  for k,v in pairs(top) do
    coroutine.resume(v.co, v)
  end
end


