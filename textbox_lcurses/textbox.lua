
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


  local curses  = require"curses"
  local stringx = require"pl.stringx"
  local utils   = require"pl.utils"
  local dirtree = require"dirtree"


  M.all_windows = {}
  M.active_window = ""


  function M.rpad(str, len)
    return str .. string.rep(" ", len - #str)
  end


  function M.htmlcolor(id, colorcode)
    local blue  = (colorcode & 0xff) * 1000 // 255
    colorcode   = colorcode >> 8
    local green = (colorcode & 0xff) * 1000 // 255
    colorcode   = colorcode >> 8
    local red   = (colorcode & 0xff) * 1000 // 255
    curses.init_color(id, red, green, blue)
  end


  function M.color(name, color)
    M.all_windows[name].win:attron(curses.color_pair(color))
  end


  function M.init_colors()
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


  function M.tmerge(t1, t2)
    for k,v in pairs(t2) do
      t1[k] = v
    end
  end

  function M.update(name, cfg)
    local this = M.all_windows[name]
    M.tmerge(this, cfg)
  end


  function M.newbox(cfg)
    local this = {}
    M.tmerge(this, cfg)
    this.isbox = true
    this.win = curses.newwin(this.height, this.width, this.starty, this.startx)
    return this
  end


  function M.new(cfg)

    cfg.name   = cfg.name or tostring(#M.all_windows)
    cfg.hasborder = cfg.hasborder or false
    cfg.height = cfg.height or 10
    cfg.width  = cfg.width  or 10
    cfg.starty = cfg.starty or 10
    cfg.startx = cfg.startx or 10

    local name = cfg.name

    if cfg.hasborder then
      local boxname = name .. "_box"
      M.all_windows[boxname] = M.newbox({name = boxname, height = cfg.height, width = cfg.width, starty = cfg.starty, startx = cfg.startx})
      cfg.txt_height = cfg.height - 2
      cfg.txt_width  = cfg.width - 2
      cfg.txt_starty = cfg.starty + 1
      cfg.txt_startx = cfg.startx + 1
    else
      cfg.txt_height = cfg.height
      cfg.txt_width  = cfg.width
      cfg.txt_starty = cfg.starty
      cfg.txt_startx = cfg.startx
    end

    local this = {}
    M.tmerge(this, cfg)
    this.isbox = false
    this.win   = curses.newwin(cfg.txt_height, cfg.txt_width, cfg.txt_starty, cfg.txt_startx)
    M.all_windows[name] = this
    if this.active then
      M.active_window = "name"
    end
    if this.txtcolor then
      M.color(name, this.txtcolor)
    end

    if this.filename then
      this.lines = utils.readlines(this.filename)
    end
    
  end


  function M.refresh(name)
    local this = M.all_windows[name]
    if this.hasborder then
      local box_name = name .. '_box'
      local color = M.white_on_black
      if this.active then
        M.color(box_name, M.yellow_on_black)
      end
      M.all_windows[box_name].win:box(0, 0)
      M.all_windows[box_name].win:refresh()
    end
    this.win:refresh()
  end


  function M.print_table(name, t, action)
    action = action or 'init' -- 'init', 'insert'
    local this = M.all_windows[name]
    local txt_width = this.txt_width - 1

    this.win:move(0,0)
    for i,v in ipairs(t) do
      local line = stringx.rstrip(v, "\n\r")
      local endl = (line ~= v)
      line = stringx.shorten(line, txt_width)

      if this.rpad then
        line = M.rpad(line, txt_width)
      end
      local lastline = (i == #t)
      if endl or not lastline then
        line = line .. "\n"
      end
      this.win:addstr(line)
    end
    this.win:clrtobot()
    M.refresh(name)
  end



  function M.print(name, str, action)
    M.print_table(name, stringx.splitlines(str, true), action)
  end



  -- To display Lua errors, we must close curses to return to
  -- normal terminal mode, and then write the error to stdout.
  function M.err(err)
    curses.endwin()
    print "Caught an error:"
    print(debug.traceback(err, 2))
    os.exit(2)
  end


return M


