local dirtree = {}


  local lfs = require"lfs"
--  local curses = require"lcurses"


  function dirtree.rpad(str, len)
    return str .. string.rep(" ", len - #str)
  end


  function dirtree.count(haystack, needle)
    local _, cnt = string.gsub(haystack, needle, '')
    return cnt
  end


  function dirtree.fileinfo(filename, sep)
    sep = sep or package.config:sub(1,1)
    local f = {}
    f.fullname = filename
    f.parent, f.name = filename:match('(.*' .. sep .. ')(.*)')
    f.mode = lfs.attributes(filename).mode
    f.isdir = f.mode == 'directory'
    f.level = dirtree.count(f.parent, '/') - 1
    return f
  end


  function dirtree.getfiles(dir, recursive, luapat_filter, filelist)
    recursive = recursive or false
    luapat_filter = luapat_filter or ""
    sep = sep or package.config:sub(1,1)

    filelist = filelist or {}	-- use provided list or create a new one
    for filename in lfs.dir(dir) do
      if filename ~= "." and filename ~= ".." then
        local full_filename = dir .. sep .. filename
        local match = dirtree.count(full_filename, luapat_filter) > 0
        local info = dirtree.fileinfo(full_filename)
        if match or info.isdir then
          filelist[#filelist+1] = info
          if recursive and info.isdir then
            dirtree.getfiles(full_filename, true, luapat_filter, filelist)
          end
        end
      end
    end
    return filelist
  end


  function dirtree.str(path, glob_filter)
    local path = path or "."
    local glob_filter = glob_filter or ""
    local luapat_filter = glob_filter:gsub('%*', '.*')
    local recursive = true
    local files = dirtree.getfiles(path, recursive, luapat_filter)
    local file_str = ""
    if #files > 0 then
      for _, f in ipairs(files) do
        local indent = dirtree.rpad("", 2*f.level)
        local icon = f.isdir and 'v ' or ''
        local line = indent .. icon .. f.name .. "\n"
        file_str = file_str .. line
      end
    end
    return file_str
  end

-- ==================================================================
-- ==================================================================

  function dirtree.test()
    local path = arg[1] or "."
    local glob_filter = arg[2] or ""
    print(dirtree.str(path, glob_filter))
  end

--   dirtree.test()

  return dirtree

