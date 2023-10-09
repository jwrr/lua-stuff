
co1 = coroutine.create(function()
  print("in co1 1")
  coroutine.yield()
  print("in co1 2")
  coroutine.yield()
  print("in co1 3")
  coroutine.yield()
  print("in co1 4")
end)


print("in main 1")
coroutine.resume(co1)
print("in main 2")
coroutine.resume(co1)
print("in main 3")
coroutine.resume(co1)
print("in main 4")
coroutine.resume(co1)
print("in main 5")
coroutine.resume(co1)
print("in main 6")



