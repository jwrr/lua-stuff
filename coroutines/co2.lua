
local coroutine_table = {}
for i=1,10 do
  print("Creating coroutine: ", i)
  coroutine_table[i] = coroutine.create(function()
    print("in co1 1")
    coroutine.yield()
    print("in co1 2")
    coroutine.yield()
    print("in co1 3")
    coroutine.yield()
    print("in co1 4")
  end)
end




print("in main 1")
for i=1,10 do coroutine.resume(coroutine_table[i]) end
print("in main 2")
for i=1,10 do coroutine.resume(coroutine_table[i]) end
print("in main 3")
for i=1,10 do coroutine.resume(coroutine_table[i]) end
print("in main 4")
for i=1,10 do coroutine.resume(coroutine_table[i]) end
print("in main 5")
for i=1,10 do coroutine.resume(coroutine_table[i]) end
print("in main 6")
for i=1,10 do coroutine.resume(coroutine_table[i]) end
print("in main done")



