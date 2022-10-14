
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

  M.lines = {}
  M.linenumber = 1
  M.column = 1
  M.insert_mode = true -- overwrite = false
  M.filename = "text.txt"


  function M.save_file_from_table(filename, lines)
    filename = filename or M.filename
    local lines = lines or M.lines
    local f = io.open(filename, 'w')
    for _,line in ipairs(lines) do
      f:write(line .. '\n')
    end
    f:close()
  end
  
  function M.read_file_into_table(filename)
    filename = filename or textbox.filename
    M.filename = filename
    textbox.dbg.print('filename=' ..  filename)

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


  function M.print()
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


  function M.enter_text(str)
    str = str or textbox.input.ch or ''
    if M.insert_mode then
      M.insert(str)
    else
      M.overwrite(str)
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


  function M.delete_char(n)
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
      M.enter_text()
    end
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
    textbox.filename = filename or textbox.filename or ''
    if textbox.filename == '' then
      local tmp_window = textbox.active_window
      textbox.active_window = "nav"
      textbox.refresh(tmp_window)
    else
      textbox.read_file_into_table(textbox.filename)
    end
  end


  function M.quit()
    textbox.quit(true)
  end



  M.down       = function() M.movey(1) end
  M.up         = function() M.movey(-1) end
  M.left       = function() M.movex(-1) end
  M.right      = function() M.movex(1) end
  M.delete     = function() M.delete_char(1) end
  M.backspace  = function() if M.movex(-1) then M.delete_char(1) end end
  M.open       = function() M.read_file_into_table() end
  M.save       = function() M.save_file_from_table() end

  function M.register_functions(wname)
    local tbi = textbox.input
    tbi.bind_seq(wname, 'open',  M.open_file, "Open file for editing")
    tbi.bind_seq(wname, 'quit',  M.quit, "Quit")
    tbi.bind_key(wname, tbi.KEY_DOWN_ARROW,   M.down,  "Move down")
    tbi.bind_key(wname, tbi.KEY_UP_ARROW,     M.up,    "Move up")
    tbi.bind_key(wname, tbi.KEY_LEFT_ARROW,   M.left,  "Move left")
    tbi.bind_key(wname, tbi.KEY_RIGHT_ARROW,  M.right, "Move right")
    tbi.bind_key(wname, tbi.KEY_DELETE,       M.delete, "Delete character")
    tbi.bind_key(wname, tbi.KEY_BACKSPACE,    M.backspace, "Delete previous character")
    tbi.bind_key(wname, tbi.KEY_CTRL_O,       M.open,  "Open file")
    tbi.bind_key(wname, tbi.KEY_CTRL_S,       M.save,  "Save file")
  end

return M

