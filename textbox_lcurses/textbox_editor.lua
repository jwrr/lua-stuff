
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

  local textbox = require'textbox'

  M.wname = 'editor'

  function M.new(cfg)
    cfg['name'] = M.wname
    textbox.new(cfg)
    M.register_functions(M.wname)
  end

  M.txt = ''
  M.lines = {}
  M.linenumber = 1
  M.column = 1
  M.insert_mode = true -- overwrite = false
  M.filename = "text.txt"

  function M.save_table(filename, lines)
    filename = filename or M.filename
    local lines = lines or M.lines
    local f = io.open(filename, 'w')
    for _,line in ipairs(lines) do
      f:write(line .. '\n')
    end
    f:close()
  end
  
  function M.read_table(filename)
--     textbox.dbg.print("read")
    filename = filename or M.filename
    local lines = {}
    for line in io.lines(filename) do
      table.insert(lines, line)
    end
    M.lines = lines
    M.linenumber = 1
    M.column = 1
  end
  

  function M.min(a, b)
    return (a < b) and a or b
  end


  function M.max(a, b)
    return (a > b) and a or b
  end


  function M.print(txt)
    txt = txt or M.txt
    textbox.print_lines(M.wname, M.lines, true)
    M.column = M.column or 1
    M.lines[M.linenumber] = M.lines[M.linenumber] or ''
    local x = M.min(M.column, #M.lines[M.linenumber]+1) - 1
    local y = M.linenumber - 1
    textbox.moveto(M.wname, y, x)
    textbox.refresh(M.wname)
  end


  function M.trim_cr(str)
    str = str or ''
    local ends_with_cr = str:sub(#str) == '\n'
    if ends_with_cr then
      str = str:sub(1, #str-1)
    end
    return str
  end


  function M.overwrite(str)
  end


  function M.insert(str)
    local str2 = M.trim_cr(str)
    local new_str_ends_with_cr = #str2 ~= #str
    local line = M.lines[M.linenumber] or ''
    local col = M.column
    line = line:sub(1, col-1) .. str2 .. line:sub(col, #line)
    M.column = col + #str2
    M.lines[M.linenumber] = line
    if new_str_ends_with_cr then
      M.lines[M.linenumber] = line:sub(1, M.column-1)
      M.linenumber = M.linenumber + 1
      table.insert(M.lines, M.linenumber, line:sub(M.column))
      M.column = 1
    end
  end


  function M.delete_lines(linenumber, n)
    linenumber = linenumber or M.linenumber
    n = n or 1
    for i = linenumber, #M.lines-n  do
      M.lines[i] = M.lines[i+n]
    end
    for i = #M.lines-n+1, #M.lines do
      table.remove(M.lines)
    end
  end


  function M.join_lines(linenumber)
    linenumber = linenumber or M.linenumber
    if linenumber < #M.lines then
       M.lines[linenumber] = M.lines[linenumber] .. M.lines[linenumber+1]
       M.delete_lines(linenumber + 1, 1)
    end
  end


  function M.delete(n)
    n = n or 1
    local line = M.lines[M.linenumber] or ''
    local col = M.column
    local removing_cr = col+n > #line+1
    line = line:sub(1, col-1) .. line:sub(col+n)
    M.lines[M.linenumber] = line
    if removing_cr then
      M.join_lines()
    end
  end


  function M.getchar()
    local is_text = textbox.input.getch()
    if is_text then
      local c = textbox.input.c
      if textbox.input.keystroke_exists(c) then
        textbox.input.run(c)
      elseif c == M.KEY_LEFT_ARROW then
        M.movex(-1)
      elseif c == M.KEY_RIGHT_ARROW then
        M.movex(1)
      elseif c == M.KEY_UP_ARROW then
        M.movey(-1)
      elseif c == M.KEY_DOWN_ARROW then
        M.movey(1)
      elseif c == M.KEY_DELETE then
        M.delete(1)
      elseif c == M.KEY_BACKSPACE then
--        M.txt = M.txt:sub(1, -2)
        if M.movex(-1) then
          M.delete(1)
        end
      elseif c == M.KEY_CTRL_O then
        M.read_table()
      elseif c == M.KEY_CTRL_S then
        M.save_table()
      elseif textbox.input.ch then
        if M.insert_mode then
          M.insert(textbox.input.ch)
        else
          M.overwrite(textbox.input.ch)
        end
        M.txt = M.txt .. textbox.input.ch
      end
    end
    textbox.resize_windows()
    return not textbox.quit()
  end

-- ==========================================================================
-- ==========================================================================

  function M.movey(delta_y)
    delta_y = delta_y or 0
    local ln1 = M.linenumber
    if delta_y ~= 0 then
      local ln = M.linenumber + delta_y
      ln = M.max(ln, 1)
      M.linenumber = M.min(ln, #M.lines)
    end
    local success = M.linenumber ~= ln1
    return success
  end


  function M.colmax(linenumber)
    linenumber = linenumber or M.linenumber
    return #M.lines[M.linenumber] + 1
  end


  function M.movex(delta_x)
    delta_x = delta_x or 0
    if delta_x == 0 then return  end
    local col1 = M.column
    local ln1 = M.linenumber
    local col = M.min(M.column, M.colmax())
    col = col + delta_x
    if delta_x < 0 then
      while (col < 1) and M.movey(-1) do
        col = M.colmax() + col -- col is negative
      end
    else
      local colmax = M.colmax()
      while (col > colmax) and M.movey(1) do
        col = colmax - col
        colmax = M.colmax()
      end
    end
    col = M.max(col, 1)
    M.column = M.min(col, M.colmax())
    local success = (M.column ~= col1) or (M.linenumber ~= ln1)
    return success
  end


  function M.open_file(filename)
    filename = filename or ''
    if filename == '' then
      local tmp_window = textbox.active_window
      textbox.active_window = "nav"
      textbox.refresh(tmp_window)
    end
  end


  function M.quit()
    textbox.quit(true)
  end


  M.KEY_DOWN_ARROW  = 258
  M.KEY_UP_ARROW    = 259
  M.KEY_LEFT_ARROW  = 260
  M.KEY_RIGHT_ARROW = 261
  M.KEY_BACKSPACE   = 263
  M.KEY_DELETE      = 330
  M.KEY_CTRL_O      = 15  -- opqrs
  M.KEY_CTRL_S      = 19

  M.down  = function() M.movey(-1) end
  M.up    = function() M.movey(1) end
  M.left  = function() M.movex(-1) end
  M.right = function() M.movex(1) end
  M.open  = function() M.read_table() end
  M.save  = function() M.save_table() end

  function M.register_functions(wname)
    textbox.input.bind_seq(wname, 'open',  M.open_file, "Open file for editing")
    textbox.input.bind_seq(wname, 'quit',  M.quit, "Quit")
    textbox.input.bind_key(wname, M.KEY_DOWN_ARROW,   M.down,  "Move down")
    textbox.input.bind_key(wname, M.KEY_UP_ARROW,     M.up,    "Move up")
    textbox.input.bind_key(wname, M.KEY_LEFT_ARROW,   M.left,  "Move left")
    textbox.input.bind_key(wname, M.KEY_RIGHT_ARROW,  M.right, "Move right")
    textbox.input.bind_key(wname, M.KEY_CTRL_O,       M.open,  "Open file")
    textbox.input.bind_key(wname, M.KEY_CTRL_S,       M.save,  "Save file")
  end

return M

