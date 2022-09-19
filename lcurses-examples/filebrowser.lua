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
local textbox = require"textbox"
local dirtree = require"dirtree"


function filebrowser()
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

xpcall(filebrowser, textbox.err)
