
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
  M.screen_first_line = 1
  M.screen_last_line = 0
  M.insert_mode = true -- overwrite = false
  M.filename = "text.txt"
  M.comment = '#'
  M.select_first_line = 0
  M.select_last_line = 0
  M.select_first_column = 0
  M.select_last_column = 0

  M.cfg = {}
  M.cfg.lines_from_top = 7
  M.cfg.lines_from_bot = 10
  M.cfg.keep_centered  = false
  M.cfg.show_line_numbers = true
  M.cfg.auto_indent = true
  M.cfg.auto_comment = true
  M.cfg.color_normal   = tb.color.white_on_black
  M.cfg.color_selected = tb.color.black_on_white

  function M.moveto()
    tb.moveto(M, M.y, M.x)
  end


  function M.print()
    local refresh = false
    tb.print_lines2(M, refresh)
    M.column = M.column or 1
    M.lines[M.line_number] = M.lines[M.line_number] or ''
    M.x = tb.min(M.column-1, #M.lines[M.line_number])
    M.y = M.line_number - M.screen_first_line
    tb.moveto(M, M.y, M.x)
    tb.refresh(M.wname)
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


  function M.auto_comment()
    if M.cfg.auto_comment then
      local prev_is_comment = tb.starts_with(M.lines[M.line_number-1], '%s*' ..  M.comment)
      local prev_prev_is_comment = tb.starts_with(M.lines[M.line_number-2], '%s*' ..  M.comment)
      local next_is_comment = tb.starts_with(M.lines[M.line_number+1], '%s*' ..  M.comment)
      if prev_is_comment then
        if prev_prev_is_comment or next_is_comment then
          local prev_line = M.lines[M.line_number-1] or ''
          local comment = string.match(prev_line, '^(%s*' .. M.comment .. '%s*)') or ''
          M.lines[M.line_number] = comment
          M.column = #comment + 1
          return true
        end
      end
    end
    return false
  end


  function M.auto_indent()
    if M.cfg.auto_indent then
      local leading_whitespace = tb.get_whitespace(M.lines[M.line_number-1])
      if leading_whitespace then
        M.lines[M.line_number] = leading_whitespace
        M.column = #leading_whitespace + 1
        return true
      end
    end
    return false
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
      if not M.auto_comment() then
        M.auto_indent()
      end
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


  function M.on_keypress()
    local is_text = tb.input.getch()
    if is_text then
      M.enter_text()
    end
    return not tb.quit()
  end

-- ==========================================================================
-- ==========================================================================

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
      tb.read_file_into_table(M)
      M.filename = tb.filename
      tb.filename = nil
      tb.all_windows["nav"].hidden = true
      tb.resize_windows(true)
    end
  end


  function M.quit()
    tb.quit(true)
  end


  function M.movey(delta_y)
    return tb.movey(M, delta_y)
  end


  function M.movex(delta_x)
    return tb.movex(M, delta_x)
  end

  function M.goto_line(y)
    return tb.goto_line(M, y)
  end

  M.down         = function() M.movey(1) end
  M.up           = function() M.movey(-1) end
  M.left         = function() M.movex(-1) end
  M.right        = function() M.movex(1) end
  M.goto_lnum    = function() M.goto_line(42) end
  M.goto_sol     = function() M.column = 1 end
  M.goto_eol     = function() M.column = #M.lines[M.line_number]+1 end 
  M.pagedown     = function() M.movey(tb.num_usable_lines(M.wname)) end
  M.pageup       = function() M.movey(-1*tb.num_usable_lines(M.wname)) end
  M.home         = function() M.goto_line(1) end
  M.endx         = function() M.goto_line(#M.lines) end
  
  M.delete       = function()
    if M.select_first_line > 0 then
      local num_selected_lines = M.select_last_line - M.select_first_line + 1
      M.delete_lines(M.select_first_line, num_selected_lines)
      M.line_number = M.select_first_line
      M.select_first_line = 0
      M.select_last_line = 0
    else
      M.delete_char(1)
    end
  end
  M.backspace    = function() if M.movex(-1) then M.delete_char(1) end end
  M.open         = function() M.open_file() end
  M.save         = function() tb.save_file_from_table() end
  M.select_line  = function()
    tb.dbg.clear("select_line: "..tostring(M.select_first_line)..' '..tostring(M.select_last_line))
    if M.select_first_line == 0 then
      M.select_first_line = M.line_number
    end
    M.select_last_line = M.line_number
    M.down()
  end
  M.show_line_numbers = function() M.cfg.show_line_numbers = true end
  M.hide_line_numbers = function() M.cfg.show_line_numbers = false end

  function M.register_functions(wname)
    local tbi = tb.input
    local keys = tb.keys
    tbi.bind_seq(wname, 'open',  M.open_file, "Open file for editing")
    tbi.bind_seq(wname, 'quit',  M.quit, "Quit")
    tbi.bind_seq(wname, 'jj',    M.join_lines,            "Join lines")
    tbi.bind_seq(wname, 'ln',    M.show_line_numbers,     "Show line numbers")
    tbi.bind_seq(wname, 'LN',    M.hide_line_numbers,     "Hide line numbers")
    tbi.bind_key(wname, keys.DOWN_ARROW,   M.down,        "Move down")
    tbi.bind_key(wname, keys.UP_ARROW,     M.up,          "Move up")
    tbi.bind_key(wname, keys.LEFT_ARROW,   M.left,        "Move left")
    tbi.bind_key(wname, keys.RIGHT_ARROW,  M.right,       "Move right")
    tbi.bind_key(wname, keys.DELETE,       M.delete,      "Delete character")
    tbi.bind_key(wname, keys.BACKSPACE,    M.backspace,   "Delete previous character")
    tbi.bind_key(wname, keys.CTRL_G,       M.goto_lnum,   "Goto linenumber")
    tbi.bind_key(wname, keys.CTRL_L,       M.select_line, "Select Line")
    tbi.bind_key(wname, keys.CTRL_O,       M.open,        "Open file")
    tbi.bind_key(wname, keys.CTRL_S,       M.save,        "Save file")
    tbi.bind_key(wname, keys.PAGEUP,       M.pageup,      "Page up")
    tbi.bind_key(wname, keys.PAGEDOWN,     M.pagedown,    "Page down")
    tbi.bind_key(wname, keys.HOME,         M.goto_sol,    "Goto start of line")
    tbi.bind_key(wname, keys.END,          M.goto_eol,    "Goto end of line")
    tbi.bind_key(wname, keys.CTRL_HOME,    M.home,        "Goto 1st line")
    tbi.bind_key(wname, keys.CTRL_END,     M.endx,        "Goto last line")
  end

return M

