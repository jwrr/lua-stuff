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
local dirtree = require"dirtree"

function filebrowser()
  local stdscr = curses.initscr()

--   curses.cbreak()
  curses.raw()
  curses.echo(false)
  curses.nl(true)
  curses.keypad()

  textbox.init_colors()

  textbox.new({name = 'banner',  height =  1, width = 137, starty =  0, startx =  0, hasborder = false, txtcolor = textbox.black_on_white, rpad = true })
  textbox.new({name = 'nav',     height = 40, width =  35, starty =  1, startx =  0, hasborder = true,  txtcolor = textbox.black_on_white, rpad  = true})
  textbox.new({name = 'status',  height = 10, width = 100, starty = 31, startx = 36, hasborder = true,  txtcolor = textbox.red_on_black })
  textbox.new({name = 'editor',  height = 30, width = 100, starty =  1, startx = 36, hasborder = true,  txtcolor = textbox.white_on_black, active = true })

  local banner = "Enter Ctrl-Q to quit"
  local txt = ''

  repeat
    local file_str = dirtree.str("..")
    local file_tab = dirtree.lines("..")

    textbox.print('banner', banner)
    textbox.print_table('nav', file_tab)
    textbox.print('status', txt)
    textbox.print('editor', txt)

    local c = stdscr:getch()
    local is_quit_key  = (c == 17)
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

    if is_backspace_key then
      txt = txt:sub(1, -2)
    else
      txt = txt .. ch
    end

  until is_quit_key

  curses.endwin()
end

xpcall(filebrowser, textbox.err)
