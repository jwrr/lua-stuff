# lua-stuff
Lua stuff. The is a playground to try out C++/Lua using Sol2.  Most stuff is  is in a broken/experimental state that I wouldn't recommend.

Install Lua 5.4
----------- ---

* [Lua Download & Build Instructions](https://www.lua.org/download.html)

```
wget http://www.lua.org/ftp/lua-5.4.4.tar.gz
tar zxvf lua-5.4.4.tar.gz
pushd lua-5.4.4
make all test
sudo make install
popd
lua -v
lua hello.lua
```

Install Sol2 v3.3
-----------------

From root of existing Git repo:

```
git submodule add https://github.com/ThePhD/sol2.git ./sol2
git commit -m "Add sol2 submodule"
git push
```

