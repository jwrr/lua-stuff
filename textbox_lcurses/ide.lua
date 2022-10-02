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
local stringx = require"pl.stringx"
local textbox = require"textbox"
local dirtree = require"textbox_dirtree"
local editor  = require"textbox_editor"

function filebrowser()
  local stdscr = curses.initscr()

--   curses.cbreak()
  curses.raw()
  curses.echo(false)
  curses.nl(true)
  curses.keypad()

  textbox.start_color()

  textbox.new({name = 'banner',  height =  1, width = 137, starty =  0, startx =  0, hasborder = false, color_pair = textbox.black_on_white})
  textbox.new({name = 'status',  height = 10, width = 100, starty = 31, startx = 35, hasborder = true,  color_pair = textbox.red_on_black })
  dirtree.new({height = 40, width =  35, starty =  1, startx =  0, hasborder = true,  color_pair = textbox.black_on_white})
  editor.new( {height = 30, width = 100, starty =  1, startx = 35, hasborder = true,  color_pair = textbox.white_on_black, active = true })


  local txt = ''

  local c = stdscr:getch()
  local banner ='Enter Ctrl-Q to quit'
  local prev_maxy, prev_maxx = stdscr:getmaxyx()
  local cnt = 0;
  repeat
    cnt = cnt + 1
    textbox.print('status', textbox.dbg_str)

    local file_tab = dirtree.lines("..")
    textbox.print_lines('nav', file_tab)

    textbox.print('banner', banner)
    if not textbox.cmd_t.mode then
--    textbox.print('status', txt)
      textbox.print('editor', txt)
    end

    local c = stdscr:getch()

    local is_quit_key  = (c == 17)
    local is_valid_key = (c <= 255)
    local is_enter_key = (c == 10)
    local is_backspace_key  = (c == 8) or (c == 127)
    local ch = is_valid_key and string.char(c) or ''

    if not textbox.cmd(c) then
      if is_backspace_key then
        txt = txt:sub(1, -2)
      else
        txt = txt .. ch
      end
    end

    local maxy, maxx = textbox.resize_windows(stdscr)
    banner = textbox.banner(c)
--       1         2         3         4         5         6                   8                   0                   2                   4
-- 4567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
  until is_quit_key

  curses.endwin()
end

xpcall(filebrowser, textbox.err)

