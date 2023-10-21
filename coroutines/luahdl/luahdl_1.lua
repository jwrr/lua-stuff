
local top = {}

top.u_testbench = {
  signal = {
    reset_n = {val = 0},
    en = {val = 0}
  },
  co = coroutine.create(function(p)
    p.signal.reset_n.val = 0
    for i=1,10 do coroutine.yield() coroutine.yield() end
    p.signal.reset_n.val = 1
    p.signal.en.val = 1
    for i=1,5 do coroutine.yield() coroutine.yield() end
    p.signal.en.val = 0
    for i=1,5 do coroutine.yield() coroutine.yield() end

    for i=1,100000 do
      coroutine.yield()
      print("in testbench", i)
      coroutine.yield()
    end
  end)
}



top.u_counter1 = {
  i = {
    reset_n = top.u_testbench.signal.reset_n,
    en      = top.u_testbench.signal.en,
    step_size = {val = 1}
  },
  o = {
    cnt = {val = 0}
  },
  signal = {
  },
  co = coroutine.create(function(p)
    local cnt
    while true do
      if p.i.reset_n.val == 1 then
        if p.i.en.val == 1 then
          cnt = p.o.cnt.val + p.i.step_size.val
        end
      else
        cnt = 0
      end
      coroutine.yield()
      p.o.cnt.val = cnt
      print("in u_counter1. cnt = ", p.o.cnt.val)
      coroutine.yield()
    end
  end)
}



top.u_counter2 = {
  i = {
    reset_n = top.u_testbench,
    step_size = {val = 2}
  },
  o = {
    cnt = {val = 0}
  },
  signal = {
  },
  co = coroutine.create(function(p)
    while true do
      local cnt = p.o.cnt.val + p.i.step_size.val
      coroutine.yield()
      p.o.cnt.val = cnt
      print("in u_counter2. cnt = ", p.o.cnt.val)
      coroutine.yield()
    end
  end)
}



top.u_adder = {
  i = {
    reset_n = top.u_testbench,
    a = top.u_counter1.o.cnt,
    b = top.u_counter2.o.cnt
  },
  o = {
    sum = {val = 0}
  },
  signal = {
  },
  co = coroutine.create(function(p)
    while true do
      local sum = p.i.a.val + p.i.b.val
      coroutine.yield()
      p.o.sum.val = sum
      print("in u_adder. sum = ", p.o.sum.val)
      coroutine.yield()
    end
  end)
}


--=====================================================================
--=====================================================================


print ("START SIMULATION")

for i=1,20 do
  print("EXEC")
  for k,v in pairs(top) do
    coroutine.resume(v.co, v)
  end
  print("UPDATE")
  for k,v in pairs(top) do
    coroutine.resume(v.co, v)
  end
end


