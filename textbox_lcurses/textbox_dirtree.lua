
-- -- Copyright 2022 jwrr.com
--
-- THE MIT LICENSE
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local M = {}
  M.wname = "nav"
  M.current_line = 1;

  local textbox = require'textbox'

  function M.rpad(str, len, pad_ch)
    pad_ch = pad_ch or ' '
    return str .. string.rep(pad_ch, len - #str)
  end


  function M.lpad(str, len, pad_ch)
    pad_ch = pad_ch or ' '
    return string.rep(pad_ch, len) .. str
  end


  function M.count(haystack, needle)
    local _, cnt = string.gsub(haystack, needle, '')
    return cnt
  end


  function M.fileinfo(filename, sep)
    sep = sep or package.config:sub(1,1)
    local f = {}
    f.fullname = filename
    f.parent, f.name = filename:match('(.*' .. sep .. ')(.*)')
    f.mode = textbox.lfs.attributes(filename).mode
    f.isdir = f.mode == 'directory'
    f.level = M.count(f.parent, '/') - 1
    return f
  end

  M.filelist = {}

  function M.getfiles(dir, recursive, luapat_filter, filelist)
    recursive = recursive or false
    luapat_filter = luapat_filter or ""
    sep = sep or package.config:sub(1,1)

    filelist = filelist or {}	-- use provided list or create a new one
    for filename in textbox.lfs.dir(dir) do
      if filename ~= "." and filename ~= ".." then
        local full_filename = dir .. sep .. filename
        local match = M.count(full_filename, luapat_filter) > 0
        local info = M.fileinfo(full_filename)
        if match or info.isdir then
          filelist[#filelist+1] = info
          if recursive and info.isdir then
            M.getfiles(full_filename, true, luapat_filter, filelist)
          end
        end
      end
    end
    M.filelist = filelist
    return filelist
  end


  function M.lines(path, glob_filter)
    local path = path or "."
    local glob_filter = glob_filter or ""
    local luapat_filter = glob_filter:gsub('%*', '.*')
    local recursive = true
    local files = M.getfiles(path, recursive, luapat_filter)
    local lines = {}
    if #files > 0 then
      for i,f in ipairs(files) do
        local indent_ch = (i == M.current_line) and '=' or ' '
        local indent = M.rpad('', 2*f.level, indent_ch) .. ' '
        local icon = f.isdir and 'v ' or ''
        local after = (i == M.current_line) and ' '..string.rep(indent_ch, 20) or ''
        local line = indent .. icon .. f.name .. after .. '\n'
        lines[#lines+1] = line
      end
    end
    return lines
  end

  function M.str(path, glob_filter)
    local path = path or "."
    local glob_filter = glob_filter or ""
    local luapat_filter = glob_filter:gsub('%*', '.*')
    local recursive = true
    local files = M.getfiles(path, recursive, luapat_filter)
    local file_str = ""
    if #files > 0 then
      for _, f in ipairs(files) do
        local indent = M.rpad("", 2*f.level)
        local icon = f.isdir and 'v ' or ''
        local line = indent .. icon .. f.name .. "\n"
        file_str = file_str .. line
      end
    end
    return file_str
  end


  function M.print(force)
    force = force or false
    if force or textbox.active_window == M.wname then
      local files = M.lines("..")
      textbox.print_lines('nav', files)
      return true
    else
      return false
    end
  end


  function M.new(cfg)
    wname = 'nav'
    cfg['name'] = wname
    textbox.new(cfg)
    M.register_functions(wname)
  end


-- ======================================================
-- ======================================================

  function M.open(editor_window)
    editor_window = editor_window or 'editor'
    local tmp_window = textbox.active_window
    textbox.active_window = 'editor'
    textbox.refresh(editor_window)
    textbox.refresh(tmp_window)

    M.filelist[M.current_line] = M.filelist[M.current_line] or {}
    if M.filelist[M.current_line] then
      local filename = M.filelist[M.current_line].fullname
      local lines = textbox.utils.readlines(filename)
    end

  end


  function M.up()
    M.current_line = M.current_line - 1
  end


  function M.down()
    M.current_line = M.current_line + 1
  end


  M.KEY_ENTER       =  10
  M.KEY_DOWN_ARROW  = 258
  M.KEY_UP_ARROW    = 259

  function M.register_functions(wname)
    textbox.input.bind_seq(wname, 'open', M.open, "Open selected file")
    textbox.input.bind_seq(wname, 'up',   M.up,   "Scroll up to previous file")
    textbox.input.bind_seq(wname, 'down', M.down, "Scroll down to next file")
    textbox.input.bind_key(wname, M.KEY_ENTER,        M.open,  "Move down")
    textbox.input.bind_key(wname, M.KEY_DOWN_ARROW,   M.down,  "Move down")
    textbox.input.bind_key(wname, M.KEY_UP_ARROW,     M.up,    "Move up")
  end

-- ==================================================================
-- ==================================================================


  function M.test()
    local path = arg[1] or "."
    local glob_filter = arg[2] or ""
    print(M.str(path, glob_filter))
  end

--   M.test()

  return M

