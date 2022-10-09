
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


  function M.insert_string(str)
    local str2 = M.trim_cr(str)
    local ends_with_cr = #str2 ~= #str
    local line = M.lines[M.linenumber] or ''
    local col = M.column
    line = line:sub(1, col-1) .. str2 .. line:sub(col, #line)
    M.column = col + #str2
    M.lines[M.linenumber] = line
    if ends_with_cr then
      M.linenumber = M.linenumber + 1
      M.column = 1
    end
  end


  function M.overwrite_string(str)
  end


  function M.getchar()
    local is_text = textbox.input.getch()
    if is_text then
      local c = textbox.input.c
      if textbox.input.keystroke_exists(c) then
        textbox.input.run(c)
      elseif textbox.input.is_backspace_key then
        M.txt = M.txt:sub(1, -2)
      elseif c == M.KEY_LEFT_ARROW then
        M.movex(-1)
      elseif c == M.KEY_RIGHT_ARROW then
        M.movex(1)
      elseif c == M.KEY_UP_ARROW then
        M.movey(-1)
      elseif c == M.KEY_DOWN_ARROW then
        M.movey(1)
      elseif textbox.input.ch then -- ch should always exist...but just in case
        if M.insert_mode then
          M.insert_string(textbox.input.ch)
        else
          M.overwrite_string(textbox.input.ch)
        end
        M.txt = M.txt .. textbox.input.ch
      end
    end
    textbox.resize_windows()
    return not textbox.quit()
  end

-- ==========================================================================
-- ==========================================================================

  function M.movex(delta_x)
    delta_x = delta_x or 0
    if delta_x ~= 0 then
      textbox.dbg.print("movex(" .. tostring(delta_x) ..   ")")
      local colmax = #M.lines[M.linenumber] + 1
      local col = M.min(M.column, colmax)
      col = col + delta_x
      col = M.max(col, 1)
      M.column = M.min(col, colmax)
    end
  end


  function M.movey(delta_y)
    delta_y = delta_y or 0
    if delta_y ~= 0 then
      textbox.dbg.print("movey(" .. tostring(delta_y) .. ")")
      local ln = M.linenumber + delta_y
      ln = M.max(ln, 1)
      M.linenumber = M.min(ln, #M.lines)
    end
  end

  function M.open()
    local tmp_window = textbox.active_window
    textbox.active_window = "nav"
    textbox.refresh(tmp_window)
  end


  function M.quit()
    textbox.quit(true)
  end


  M.KEY_DOWN_ARROW  = 258
  M.KEY_UP_ARROW    = 259
  M.KEY_LEFT_ARROW  = 260
  M.KEY_RIGHT_ARROW = 261


  M.down  = function() M.movey(-1) end
  M.up    = function() M.movey(1) end
  M.left  = function() M.movex(-1) end
  M.right = function() M.movex(1) end

  function M.register_functions(wname)
    textbox.input.bind_seq(wname, 'open',  M.open, "Open file for editing")
    textbox.input.bind_seq(wname, 'quit',  M.quit, "Quit")
    textbox.input.bind_key(wname, M.KEY_DOWN_ARROW,   M.down,  "Move down")
    textbox.input.bind_key(wname, M.KEY_UP_ARROW,     M.up,    "Move up")
    textbox.input.bind_key(wname, M.KEY_LEFT_ARROW,   M.left,  "Move left")
    textbox.input.bind_key(wname, M.KEY_RIGHT_ARROW,  M.right, "Move right")
  end

return M

