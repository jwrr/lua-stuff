-- Copyright 2022 jwrr.com
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

  local curses  = require"curses"
  local dirtree = require"dirtree"


  local textbox = {}
  textbox.all_windows = {}


  function textbox.rpad(str, len)
    return str .. string.rep(" ", len - #str)
  end


  function textbox.color_pair(name, color)
    textbox.all_windows[name].win:attron(curses.color_pair(color))
  end


  function textbox.new(name, height, width, starty, startx, border)
    local txt_height = height
    local txt_width  = width
    local txt_starty = starty
    local txt_startx = startx

    if border then
      local box_win = curses.newwin(height, width, starty, startx)
      textbox.all_windows[name .. "_box"] = {}
      textbox.all_windows[name .. "_box"].win = box_win
      textbox.all_windows[name .. "_box"].isbox = true
      txt_height = height - 2
      txt_width  = width - 2
      txt_starty = starty + 1
      txt_startx = startx + 1
    end

    local txt_win = curses.newwin(txt_height, txt_width, txt_starty, txt_startx)
    textbox.all_windows[name] = {}
    textbox.all_windows[name].win    = txt_win
    textbox.all_windows[name].height = height
    textbox.all_windows[name].width  = width
    textbox.all_windows[name].starty = starty
    textbox.all_windows[name].startx = startx
    textbox.all_windows[name].isbox  = false
    textbox.all_windows[name].inbox  = border
  end


  function textbox.refresh(name)
    if textbox.all_windows[name].inbox then
      local box_name = name .. '_box'
      textbox.all_windows[box_name].win:box(0, 0)
      textbox.all_windows[box_name].win:refresh()
    end
    textbox.all_windows[name].win:refresh()
  end


  function textbox.print(name, str, attr)
    attr = attr or curses.A_NORMAL
    local win = textbox.all_windows[name].win
    win:attron(attr)
    win:mvaddstr(0, 0, str)
    win:attroff(attr)
    win:clrtobot()
    textbox.refresh(name)
  end


-- To display Lua errors, we must close curses to return to
-- normal terminal mode, and then write the error to stdout.
function textbox.err(err)
  curses.endwin()
  print "Caught an error:"
  print(debug.traceback(err, 2))
  os.exit(2)
end


return textbox


