
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


  local curses  = require'curses'
  local stringx = require'pl.stringx'
  local utils   = require'pl.utils'


  function M.htmlcolor(id, colorcode)
    if not curses.can_change_color() then return false end
    local blue  = (colorcode & 0xff) * 1000 // 255
    colorcode   = colorcode >> 8
    local green = (colorcode & 0xff) * 1000 // 255
    colorcode   = colorcode >> 8
    local red   = (colorcode & 0xff) * 1000 // 255
    return curses.init_color(id, red, green, blue)
  end


  function M.set_color_pair(textbox, name, color_pair)
    textbox.all_windows[name].win:attron(curses.color_pair(color_pair))
  end


  function M.start()
    M.black_on_black   = 1
    M.red_on_black     = 2
    M.green_on_black   = 3
    M.yellow_on_black  = 4
    M.blue_on_black    = 5
    M.magenta_on_black = 6
    M.cyan_on_black    = 7
    M.white_on_black   = 8
    M.black_on_white   = 9
    M.red_on_white     = 10
    M.green_on_white   = 11
    M.yellow_on_white  = 12
    M.blue_on_white    = 13
    M.magenta_on_white = 14
    M.cyan_on_white    = 15
    M.white_on_white   = 16

    curses.start_color();

    M.htmlcolor(curses.COLOR_BLACK,   0x000000)
    M.htmlcolor(curses.COLOR_RED,     0xcc3333)
    M.htmlcolor(curses.COLOR_GREEN,   0x008800)
    M.htmlcolor(curses.COLOR_YELLOW,  0xa0a000)
    M.htmlcolor(curses.COLOR_BLUE,    0x5555ff)
    M.htmlcolor(curses.COLOR_MAGENTA, 0xdd00dd)
    M.htmlcolor(curses.COLOR_CYAN,    0x008888)
    M.htmlcolor(curses.COLOR_WHITE,   0xcccccc)

    curses.init_pair(M.black_on_black,   curses.COLOR_BLACK,   curses.COLOR_BLACK)
    curses.init_pair(M.red_on_black,     curses.COLOR_RED,     curses.COLOR_BLACK)
    curses.init_pair(M.green_on_black,   curses.COLOR_GREEN,   curses.COLOR_BLACK)
    curses.init_pair(M.yellow_on_black,  curses.COLOR_YELLOW,  curses.COLOR_BLACK)
    curses.init_pair(M.blue_on_black,    curses.COLOR_BLUE,    curses.COLOR_BLACK)
    curses.init_pair(M.magenta_on_black, curses.COLOR_MAGENTA, curses.COLOR_BLACK)
    curses.init_pair(M.cyan_on_black,    curses.COLOR_CYAN,    curses.COLOR_BLACK)
    curses.init_pair(M.white_on_black,   curses.COLOR_WHITE,   curses.COLOR_BLACK)

    curses.init_pair(M.black_on_white,   curses.COLOR_BLACK,   curses.COLOR_WHITE)
    curses.init_pair(M.red_on_white,     curses.COLOR_RED,     curses.COLOR_WHITE)
    curses.init_pair(M.green_on_white,   curses.COLOR_GREEN,   curses.COLOR_WHITE)
    curses.init_pair(M.yellow_on_white,  curses.COLOR_YELLOW,  curses.COLOR_WHITE)
    curses.init_pair(M.blue_on_white,    curses.COLOR_BLUE,    curses.COLOR_WHITE)
    curses.init_pair(M.magenta_on_white, curses.COLOR_MAGENTA, curses.COLOR_WHITE)
    curses.init_pair(M.cyan_on_white,    curses.COLOR_CYAN,    curses.COLOR_WHITE)
    curses.init_pair(M.white_on_white,   curses.COLOR_WHITE,   curses.COLOR_WHITE)
  end

return M


