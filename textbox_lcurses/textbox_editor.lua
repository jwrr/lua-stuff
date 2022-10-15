
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

  local tb = require'textbox'

  M.wname = 'editor'

  function M.new(cfg)
    cfg['name'] = M.wname
    tb.new(cfg)
    M.register_functions(M.wname)
  end

  M.lines = {}
  M.line_number = 1
  M.column = 1
  M.first_line = 1
  M.last_line = 0
  M.insert_mode = true -- overwrite = false
  M.filename = "text.txt"
  
  M.cfg = {}
  M.cfg.lines_from_top = 7
  M.cfg.lines_from_bot = 10


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
    filename = filename or tb.filename
    M.filename = filename
    tb.dbg.print('filename=' ..  filename)

    local lines = {}
    for line in io.lines(filename) do
      table.insert(lines, line)
    end
    M.lines = lines
    M.line_number = 1
    M.column = 1
  end


  function M.moveto()
    tb.moveto(M.wname, M.y, M.x)
  end


  function M.print()

    local maxy, maxx = tb.getmaxyx(M.wname)
    maxy = tb.max(maxy-2, 0)
    local half_screen = maxy // 2
    
    local delta_from_top = M.line_number - M.first_line
    M.last_line = tb.min(M.first_line + maxy - 1, #M.lines)
    local delta_from_bot = M.last_line - M.line_number

    if delta_from_top < M.cfg.lines_from_top then
      M.first_line = tb.max(M.line_number - M.cfg.lines_from_top, 1)
    elseif delta_from_bot < M.cfg.lines_from_bot then
      M.actual_lines_from_top = tb.max(maxy - M.cfg.lines_from_bot, 0)
      M.first_line = tb.max(M.line_number - M.actual_lines_from_top, 1)
    end
    
--     M.first_line = tb.max(M.line_number - half_screen, 1)
    M.last_line = tb.min(M.first_line + maxy - 1, #M.lines)

    if M.last_line == #M.lines then
      M.first_line = tb.max(M.last_line - maxy + 1, 1)
    end


    tb.dbg.print("lnum="..tostring(M.line_number)..' first='..tostring(M.first_line)..' last='..tostring(M.last_line))

    tb.print_lines(M.wname, M.lines, true, M.first_line, M.last_line)
    M.column = M.column or 1
    M.lines[M.line_number] = M.lines[M.line_number] or ''
    M.x = tb.min(M.column, #M.lines[M.line_number]+1) - 1
    M.y = M.line_number - M.first_line
    tb.dbg.print("before moveto: lnum="..tostring(M.line_number)..' first='..tostring(M.first_line)..' last='..tostring(M.last_line)..' y='..tostring(y))
--    tb.moveto(M.wname, y, x)
    tb.moveto(M.wname, M.y, M.x)
    tb.refresh(M.wname)
    tb.dbg.print("after refresh")
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
    local line = M.lines[M.line_number] or ''
    local col = M.column
    line = line:sub(1, col-1) .. str2 .. line:sub(col, #line)
    M.column = col + #str2
    M.lines[M.line_number] = line
    if new_str_ends_with_cr then
      M.lines[M.line_number] = line:sub(1, M.column-1)
      M.line_number = M.line_number + 1
      table.insert(M.lines, M.line_number, line:sub(M.column))
      M.column = 1
    end
  end


  function M.enter_text(str)
    str = str or tb.input.ch or ''
    if M.insert_mode then
      M.insert(str)
    else
      M.overwrite(str)
    end
  end


  function M.delete_lines(line_number, n)
    line_number = line_number or M.line_number
    n = n or 1
    for i = line_number, #M.lines-n  do
      M.lines[i] = M.lines[i+n]
    end
    for i = #M.lines-n+1, #M.lines do
      table.remove(M.lines)
    end
  end


  function M.join_lines(line_number)
    line_number = line_number or M.line_number
    if line_number < #M.lines then
       M.lines[line_number] = M.lines[line_number] .. M.lines[line_number+1]
       M.delete_lines(line_number + 1, 1)
    end
  end


  function M.delete_char(n)
    n = n or 1
    local line = M.lines[M.line_number] or ''
    local col = M.column
    local removing_cr = col+n > #line+1
    line = line:sub(1, col-1) .. line:sub(col+n)
    M.lines[M.line_number] = line
    if removing_cr then
      M.join_lines()
    end
  end


  function M.getchar()
    local is_text = tb.input.getch()
    if is_text then
      M.enter_text()
    end
    return not tb.quit()
  end

-- ==========================================================================
-- ==========================================================================

  function M.movey(delta_y)
    delta_y = delta_y or 0
    local ln1 = M.line_number
    if delta_y ~= 0 then
      local ln = M.line_number + delta_y
      ln = tb.max(ln, 1)
      M.line_number = tb.min(ln, #M.lines)
    end
    local success = M.line_number ~= ln1
    return success
  end


  function M.colmax(line_number)
    line_number = line_number or M.line_number
    return #M.lines[M.line_number] + 1
  end


  function M.movex(delta_x)
    delta_x = delta_x or 0
    if delta_x == 0 then return  end
    local col1 = M.column
    local ln1 = M.line_number
    local col = tb.min(M.column, M.colmax())
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
    col = tb.max(col, 1)
    M.column = tb.min(col, M.colmax())
    local success = (M.column ~= col1) or (M.line_number ~= ln1)
    return success
  end


  function M.open_file(filename)
    tb.filename = filename or tb.filename or ''
    tb.dbg.clear("In open_file")
    if tb.filename == '' then
      tb.dbg.print("file is empty")
      local tmp_window = tb.active_window
      tb.all_windows["nav"].hidden = false
      tb.resize_windows(true)
      tb.active_window = "nav"
      tb.filepicker_callback = M.open_file
      tb.dbg.print("after screen resize. active window = "..tb.active_window)
    else
      tb.dbg.print("reading file")
      M.read_file_into_table(tb.filename)
      M.filename = tb.filename
      tb.filename = nil
      tb.all_windows["nav"].hidden = true
      tb.resize_windows(true)
    end
  end


  function M.quit()
    tb.quit(true)
  end



  M.down       = function() M.movey(1) end
  M.up         = function() M.movey(-1) end
  M.left       = function() M.movex(-1) end
  M.right      = function() M.movex(1) end
  M.delete     = function() M.delete_char(1) end
  M.backspace  = function() if M.movex(-1) then M.delete_char(1) end end
  M.open       = function() M.open_file() end
  M.save       = function() M.save_file_from_table() end

  function M.register_functions(wname)
    local tbi = tb.input
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

