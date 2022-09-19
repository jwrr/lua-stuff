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


function textbox.rainbow(win, str, attr)
  attr = attr or curses.A_NORMAL
  win:attron(attr)
  win:mvaddstr(0, 0, '')
  for i = 1, #str do
    -- iterate 1 to 7 (skip 0 which is black / invisible)
    local attr_tmp = (i % 7) + 1
    win:attron(attr_tmp)
    local c = str:sub(i,i)
    win:addstr(c)
  end

  win:attroff(attr)
  win:clrtobot()
  win:refresh()
end


function textbox.rpad(str, len)
  return str .. string.rep(" ", len - #str)
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


function textbox.main ()
  local stdscr = curses.initscr()
  stdscr:clear()
  stdscr:refresh()

--   curses.cbreak()
  curses.raw()
  curses.echo(false)
  curses.nl(true)

  curses.start_color();
  curses.init_pair(1, curses.COLOR_BLUE,   curses.COLOR_YELLOW) -- curses.COLOR_RED, curses.COLOR_GREEN)
  curses.init_pair(2, curses.COLOR_RED,   curses.COLOR_BLACK) -- curses.COLOR_RED, curses.COLOR_GREEN)
  curses.init_pair(3, curses.COLOR_GREEN, curses.COLOR_BLACK) -- curses.COLOR_RED, curses.COLOR_GREEN)
  curses.init_pair(4, curses.COLOR_WHITE,  curses.COLOR_BLACK) -- curses.COLOR_RED, curses.COLOR_GREEN)
  curses.init_pair(5, 15,  0) -- curses.COLOR_RED, curses.COLOR_GREEN)
  
  local height = 40
  local width = 35
  local starty = 1
  local startx = 0
  local name = 'explorer'
  local border = true
  textbox.new(name, height, width, starty, startx, border)

  startx = width + 1
  width  = 100
  height = 30
  textbox.new("text", height, width, starty, startx, border)

  starty = starty + height
  height = 10
  textbox.new("status", height, width, starty, startx, true)

  local full_width = 2*width + 1
  textbox.new('banner', 1, 136, 0, 0, false)
  local banner = "Enter Ctrl-Q to quit"
  banner = banner .. string.rep(" ", full_width - banner:len())
  textbox.print('banner', banner, curses.A_REVERSE)

  textbox.all_windows['explorer'].win:attron(curses.color_pair(3))
  textbox.all_windows['text'].win:attron(curses.color_pair(4))

  local s = ''
  local file_list = dirtree.str("..")
  textbox.print('explorer', file_list)
  textbox.print('status', s)
  textbox.print('text', s)

  local is_quit_key = false

  while not is_quit_key do
    local c = stdscr:getch()
    is_quit_key  = (c == 17)
    local is_valid_key = (c <= 255)
    local is_enter_key = (c == 10)
    local is_backspace_key  = (c == 8) or (c == 127)
    local ch = is_valid_key and string.char(c) or ''

    local ch_banner = ch
    if is_enter_key then
      ch_banner = '<cr>'
    elseif is_backspace_key then
      ch_banner = '<bs>'
    end

    local maxy, maxx = stdscr:getmaxyx()

-- --     if  maxy /= prev_maxy or maxx /= prev_maxy then
--       
--     end
    banner = "Enter Ctrl-Q to quit, '" .. ch_banner  .. "' (" .. tostring(c)  ..  '), size= ' .. tostring(maxx) .. 'x' .. tostring(maxy)
    banner = textbox.rpad(banner, full_width)
    textbox.print('banner', banner, curses.A_REVERSE)

    if is_backspace_key then
      s = s:sub(1, -2)
    else
      s = s .. ch
    end
    
    local file_list = dirtree.str("..")
    textbox.print('explorer', file_list, curses.A_NORMAL)
    textbox.print('status', s, curses.A_NORMAL)
    textbox.print('text', s, curses.A_NORMAL)

--     stdscr:mvaddstr(1, 0, s)
--     stdscr:clrtobot()
--     stdscr:refresh()
  end
  curses.endwin()
end


-- To display Lua errors, we must close curses to return to
-- normal terminal mode, and then write the error to stdout.
function textbox.err(err)
  curses.endwin()
  print "Caught an error:"
  print(debug.traceback(err, 2))
  os.exit(2)
end

xpcall(textbox.main, textbox.err)
