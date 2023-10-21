
local top = {}

top.u_testbench = {
  signal = {},
  co = coroutine.create(function(p)
    for i=1,100000 do
      print("in testbench", i)
      coroutine.yield()
    end
  end)
}



top.u_counter1 = {
  i = {
    step_size = {val = 1}
  },
  o = {
    cnt = {val = 7}
  },
  signal = {
  },
  co = coroutine.create(function(p)
    while true do
      local cnt = p.o.cnt.val + p.i.step_size.val
      print("in u_counter1. cnt = ", cnt)
      coroutine.yield()
      p.o.cnt.val = cnt
      print("in u_counter1. cnt = ", p.o.cnt.val)
      coroutine.yield()
    end
  end)
}



top.u_counter2 = {
  i = {
    step_size = {val = 2}
  },
  o = {
    cnt = {val = 7}
  },
  signal = {
  },
  co = coroutine.create(function(p)
    while true do
      local cnt = p.o.cnt.val + p.i.step_size.val
      print("in u_counter2. cnt = ", cnt)
      coroutine.yield()
      p.o.cnt.val = cnt
      print("in u_counter2. cnt = ", p.o.cnt.val)
      coroutine.yield()
    end
  end)
}



top.u_adder = {
  i = {
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
      print("in u_adder. sum = ", sum)
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

for i=1,10 do
  print("EXEC")
  for k,v in pairs(top) do
    coroutine.resume(v.co, v)
    coroutine.resume(v.co, v)
  end
  print("UPDATE")
  for k,v in pairs(top) do
    coroutine.resume(v.co, v)
    coroutine.resume(v.co, v)
  end
end


