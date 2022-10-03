
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
  M.cmd   = require'textbox_cmd'
  M.color = require'textbox_color'

  M.all_windows = {}
  M.active_window = ''
  M.dbg_str = 'dbg\n'
  

  function M.start()
    M.stdscr = curses.initscr()
    curses.raw() -- cbreak
    curses.echo(false)
    curses.nl(true)
    curses.keypad()
    M.color.start()
    return M.stdscr
  end


  function M.quit(force_quit)
    force_quit = force_quit or false
    M.force_quit = M.force_quit or force_quit
    if M.cmd.is_quit_key or M.force_quit then
      curses.endwin()
      return true
    end
    M.resize_windows()
    return false
  end


  function M.getch()
    return M.stdscr:getch()
  end


  function M.setmaxyx(maxy, maxx)
    M.maxy = maxy
    M.maxx = maxx
  end


  function M.getmaxyx()
    return M.maxy, M.maxx
  end


  function M.rpad(str, len)
    return str .. string.rep(" ", len - #str)
  end
  

  function M.replace_char(pos, str, ch)
    return str:sub(1, pos-1) .. ch .. str:sub(pos+1)
  end



  function M.shallow_merge(t1, t2)
    for k,v in pairs(t2) do
      t1[k] = v
    end
  end


  function M.newbox(cfg)
    local this = {}
    M.shallow_merge(this, cfg)
    this.isbox = true
    this.win = curses.newwin(this.height, this.width, this.starty, this.startx)
    return this
  end


  function M.update(cfg)
    cfg.name   = cfg.name or "error-missing-name"
    local this = M.all_windows[cfg.name] or {}
    cfg.hasborder = cfg.hasborder or this.hasborder
    cfg.height = cfg.height or this.height
    cfg.width  = cfg.width  or this.width
    cfg.starty = cfg.starty or this.starty
    cfg.startx = cfg.startx or this.startx
    local name = cfg.name

    if cfg.hasborder then
      local boxname = name .. "_box"
      thisbox = M.all_windows[boxname]
      if cfg.height ~= this.height or cfg.width ~= this.width then
        thisbox.win:resize(cfg.height, cfg.width)
        thisbox.win:clear()
        thisbox.win:box(0,0)
      end
      if cfg.starty ~= this.starty or cfg.startx ~= thisbox.x then
        thisbox.win:move_window(cfg.starty, cfg.startx)
        thisbox.win:clear()
        thisbox.win:box(0,0)
      end

      cfg.txt_height = cfg.height - 2
      cfg.txt_width  = cfg.width - 2
      if cfg.txt_height < 1 then cfg.txt_height = 1 end
      if cfg.txt_width < 1 then cfg.txt_width = 1 end
      cfg.txt_starty = cfg.starty + 1
      cfg.txt_startx = cfg.startx + 1
    else
      cfg.txt_height = cfg.txt_height or this.txt_height
      cfg.txt_width  = cfg.txt_width  or this.txt_width
      cfg.txt_starty = cfg.txt_starty or this.txt_starty
      cfg.txt_startx = cfg.txt_startx or this.txt_startx
    end


    if cfg.txt_height ~= this.txt_height or cfg.txt_width ~= this.txt_width then
      this.win:resize(cfg.txt_height, cfg.txt_width)
      this.win:clear()
    end
    if cfg.txt_starty ~= this.txt_starty or cfg.txt_startx ~= this.txt_startx then
      this.win:move_window(cfg.txt_starty, cfg.txt_startx)
      this.win:clear()
    end

    M.shallow_merge(this, cfg)

    if this.active then
      M.active_window = name
    end
    if this.color_pair then
      M.color.set_color_pair(M, name, this.color_pair)
    end

    this.win:wbkgd(curses.color_pair(this.color_pair))

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
    M.shallow_merge(this, cfg)
    this.isbox = false
    this.win   = curses.newwin(cfg.txt_height, cfg.txt_width, cfg.txt_starty, cfg.txt_startx)

    M.all_windows[name] = this
    M.all_windows[name].id = #M.all_windows[name]
    M.all_windows[name].window_specific_commands = {}
    M.all_windows[name].window_specific_command_description = {}

    if this.active then
      M.active_window = name
    end
    if this.color_pair then
      M.color.set_color_pair(M, name, this.color_pair)
    end

    this.win:wbkgd(curses.color_pair(this.color_pair))

    if this.filename then
      this.lines = utils.readlines(this.filename)
    end

  end


  function M.resize_windows()
    local stdscr = M.stdscr
    local prev_maxy, prev_maxx = M.getmaxyx()
    local maxy, maxx = stdscr:getmaxyx()
    if  maxy ~= prev_maxy or maxx ~= prev_maxx then
      M.setmaxyx(maxy, maxx)
      M.update({name = "banner", width = maxx})
      M.update({name = "editor", width = maxx - 36, height = maxy - 11})
      M.update({name = "status", width = maxx - 36, starty = maxy - 10})
      M.update({name = "nav",    height = maxy-1})
    end
    return maxy, maxx
  end


  function M.refresh(name)
    local this = M.all_windows[name]
    if this.hasborder then
      local box_name = name .. '_box'
      local color = M.white_on_black
      if M.active_window == name then
        M.color.set_color_pair(M, box_name, M.color.red_on_black)
      else
        M.color.set_color_pair(M, box_name, M.color.white_on_black)
      end
      M.all_windows[box_name].win:box(0, 0)
      M.all_windows[box_name].win:refresh()
    end
    this.win:refresh()
  end


  function M.refresh_all()
    for k,v in ipairs(M.all_windows) do
      M.refresh(k)
    end
  end


  function M.print_lines(name, lines, action)
    action = action or 'init' -- 'init', 'insert'
    local this = M.all_windows[name]
    local txt_width = this.txt_width - 1
    this.win:move(0,0)
    for i,line1 in ipairs(lines) do
      local line = stringx.rstrip(line1, "\n\r")
      local has_eol = (line ~= line1)
      local is_lastline = (i == #lines)
      line = stringx.shorten(line, txt_width)
      if has_eol or not is_lastline then
        line = line .. "\n"
      end
      this.win:addstr(line)
    end
    this.win:clrtobot()
    M.refresh(name)
  end


  function M.print(name, str, action)
    M.print_lines(name, stringx.splitlines(str, true), action)
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


