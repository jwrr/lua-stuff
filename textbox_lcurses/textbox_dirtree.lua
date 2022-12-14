
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
  M.wname = 'nav'
  M.line_number = 1;

  local tb = require'textbox'

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
    f.mode = tb.lfs.attributes(filename).mode
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
    for filename in tb.lfs.dir(dir) do
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


  function M.read_files_into_lines(path, glob_filter)
    local path = path or "."
    local glob_filter = glob_filter or ""
    local luapat_filter = glob_filter:gsub('%*', '.*')
    local recursive = true
    local files = M.getfiles(path, recursive, luapat_filter)
    local lines = {}
    if #files > 0 then
      for i,f in ipairs(files) do
        local indent_ch = (i == M.line_number) and '=' or ' '
        local indent = M.rpad('', 2*f.level, indent_ch) .. ' '
        local icon = f.isdir and 'v ' or ''
        local after = (i == M.line_number) and ' '..string.rep(indent_ch, 20) or ''
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
    if force or tb.active_window == M.wname then
      M.lines = M.read_files_into_lines("..")
      local refresh = true
      tb.print_lines2(M, refresh)
      return true
    else
      return false
    end
  end


  function M.new(cfg)
    wname = M.wname
    cfg['name'] = wname
    tb.new(cfg)
    M.register_functions(wname)
  end


-- ======================================================
-- ======================================================

  function M.open_file(editor_window)
    editor_window = editor_window or 'editor'
    local tmp_window = tb.active_window
    tb.active_window = 'editor'
    tb.refresh(editor_window)
    tb.refresh(tmp_window)
    
    M.filelist[M.line_number] = M.filelist[M.line_number] or {}
    if M.filelist[M.line_number] then
      local filename = M.filelist[M.line_number].fullname
      tb.dbg.print('filename=' ..  filename)
      tb.filename = filename
      if tb.filepicker_callback then
        tb.filepicker_callback()
      end
    end
  end


--   function M.up()
--     M.line_number = M.line_number - 1
--   end
--
--
--   function M.down()
--     M.line_number = M.line_number + 1
--   end
--
--   function M.register_functions(wname)
--     local keys = tb.keys
--     tb.input.bind_seq(wname, 'open',               M.open, "Open selected file")
--     tb.input.bind_seq(wname, 'down',               M.down, "Scroll up to previous file")
--     tb.input.bind_seq(wname, 'up',                 M.up,   "Scroll up to previous file")
--     tb.input.bind_key(wname, keys.ENTER,        M.open,  "Select file and open")
--     tb.input.bind_key(wname, keys.DOWN_ARROW,   M.down,  "Move down")
--     tb.input.bind_key(wname, keys.UP_ARROW,     M.up,    "Move up")
--   end
--

  function M.movey(delta_y)
    return tb.movey(M, delta_y)
  end


  function M.movex(delta_x)
    return tb.movex(M, delta_x)
  end

  function M.goto_line(y)
    return tb.goto_line(M, y)
  end


  M.down       = function() M.movey(1) end
  M.up         = function() M.movey(-1) end
  M.left       = function() M.movex(-1) end
  M.right      = function() M.movex(1) end
  M.pagedown   = function() M.movey(tb.num_usable_lines(M.wname)) end
  M.pageup     = function() M.movey(-1*tb.num_usable_lines(M.wname)) end
  M.home       = function() M.goto_line(1) end
  M.endx       = function() M.goto_line(#M.lines) end

  M.delete     = function() M.delete_char(1) end
  M.backspace  = function() if M.movex(-1) then M.delete_char(1) end end
  M.open       = function() M.open_file() end
  M.save       = function() tb.save_file_from_table() end

  function M.register_functions(wname)
    local keys = tb.keys
    tb.input.bind_seq(wname, 'open',  M.open_file, "Open file for editing")
    tb.input.bind_seq(wname, 'quit',  M.quit, "Quit")
    tb.input.bind_key(wname, keys.DOWN_ARROW,   M.down,      "Move down")
    tb.input.bind_key(wname, keys.UP_ARROW,     M.up,        "Move up")
    tb.input.bind_key(wname, keys.PAGEUP,       M.pageup,    "Page up")
    tb.input.bind_key(wname, keys.PAGEDOWN,     M.pagedown,  "Page down")
    tb.input.bind_key(wname, keys.HOME,         M.home,      "Goto 1st line")
    tb.input.bind_key(wname, keys.END,          M.endx,      "Goto last line")
    tb.input.bind_key(wname, keys.CTRL_HOME,    M.home,      "Goto 1st line")
    tb.input.bind_key(wname, keys.CTRL_END,     M.endx,      "Goto last line")
    tb.input.bind_key(wname, keys.CTRL_O,       M.open,      "Open file")
    tb.input.bind_key(wname, keys.ENTER,        M.open,      "Select file and open")

-- --     tb.input.bind_key(wname, keys.LEFT_ARROW,   M.left,      "Move left")
--     tb.input.bind_key(wname, keys.RIGHT_ARROW,  M.right,     "Move right")
--     tb.input.bind_key(wname, keys.DELETE,       M.delete,    "Delete character")
--     tb.input.bind_key(wname, keys.BACKSPACE,    M.backspace, "Delete previous character")
--     tb.input.bind_key(wname, keys.CTRL_S,       M.save,      "Save file")

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

