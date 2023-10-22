#!/usr/local/bin/lua

local lhdl = {}

lhdl.run = function()
--   if #arg == 0 then
--     print("\nERROR: missing argument for top testbench\nExample: lua lhdl.lua dpram_tb\n")
--     os.exit()
--   end

  local runtime = 30
  if #arg > 0 then
    runtime = tonumber(arg[1])
  end

  local cnt = 0
  for i=1,runtime do
    if lhdl.finish then
      print("Simulation finished")
      break
    end
    cnt = cnt + 1
  --   print("EXEC")
    for k,v in pairs(lhdl.inst) do
      coroutine.resume(v.co, v.param, v.io)
    end
  --   print("UPDATE")
    for k,v in pairs(lhdl.inst) do
      coroutine.resume(v.co, v.param, v.io)
    end
  end
  
  print("simulation time:", cnt)

  for k,v in pairs(lhdl.inst) do
    print(k,v)
  end

  print("\nNOTE: To run longer, provide a runtime argument\nExample: lua dpram_tb.lua 10000\n\n")
    

end -- run

return lhdl

