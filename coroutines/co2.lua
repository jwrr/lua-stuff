
local co_table = {}
for i=1,10 do
  print("Creating coroutine: ", i)
  co_table[i] = coroutine.create(function(id)
    for i=1,4 do
      print("in coroutine", id, i)
      coroutine.yield()
    end
  end)
end


function all_dead(co_table)
  local dead_count = 0
  for i=1,#co_table do
    if coroutine.status(co_table[i]) == "dead" then
      dead_count = dead_count + 1
    end
  end
  return dead_count == #co_table
end


while not all_dead(co_table) do
  print("in main")
  for i=1,#co_table do coroutine.resume(co_table[i], i) end
end
print("in main done")



