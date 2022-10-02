
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


  function M.setmaxyx(maxy, maxx)
    M.maxy = maxy
    M.maxx = maxx
  end

  
  function M.getmaxyx()
    return M.maxy, M.maxx
  end


  M.all_windows = {}
  M.active_window = ""


  function M.rpad(str, len)
    return str .. string.rep(" ", len - #str)
  end


  function M.htmlcolor(id, colorcode)
    if not curses.can_change_color() then return false end
    local blue  = (colorcode & 0xff) * 1000 // 255
    colorcode   = colorcode >> 8
    local green = (colorcode & 0xff) * 1000 // 255
    colorcode   = colorcode >> 8
    local red   = (colorcode & 0xff) * 1000 // 255
    return curses.init_color(id, red, green, blue)
  end


  function M.set_color_pair(name, color_pair)
    M.all_windows[name].win:attron(curses.color_pair(color_pair))
  end


  function M.start_color()
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
    cfg.width  = cfg.width or this.width
    cfg.starty = cfg.starty or this.starty
    cfg.startx = cfg.startx or this.startx
    local name = cfg.name

    if cfg.hasborder then
      local boxname = name .. "_box"
      thisbox = M.all_windows[boxname]
      if cfg.height ~= thisbox.height or cfg.width ~= thisbox.width then
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
      M.set_color_pair(name, this.color_pair)
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
    M.all_windows[name].window_specific_commands = {}
    M.all_windows[name].id = #M.all_windows[name]
    if this.active then
      M.active_window = name
    end
    if this.color_pair then
      M.set_color_pair(name, this.color_pair)
    end
    
    this.win:wbkgd(curses.color_pair(this.color_pair))

    if this.filename then
      this.lines = utils.readlines(this.filename)
    end
    
  end


  function M.resize_windows(stdscr)
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
        M.set_color_pair(box_name, M.red_on_black)
      else
        M.set_color_pair(box_name, M.white_on_black)
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
    for i,line in ipairs(lines) do
      local line = stringx.rstrip(line, "\n\r")
      local endl = (line ~= line)
      line = stringx.shorten(line, txt_width)
      local lastline = (i == #lines)
      if endl or not lastline then
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
  
  function M.is_hotkey(str)
    return false
  end

  
--   function M.open()
--     local tmp_window = M.active_window
--     M.active_window = "nav"
--     M.refresh(tmp_window)
--   end


  M.dbg_str = "dbg\n"

  function M.register(wname, fname, func)
    local active_window = M.active_window
    M.all_windows[wname].window_specific_commands[fname] = func -- "abc"
    M.dbg_str = M.dbg_str .. "register: " .. wname .. " " .. fname .. "\n"
  end

  
  M.cmd_t = M.cmd_t or {mode = false, str = ""}
  function M.cmd(c)
    local is_esc_key = (c == 27)
    local is_enter_key = (c == 10) or (c == 13)
    if is_esc_key then
      M.cmd_t.mode = not M.cmd_t.mode
      M.cmd_t.str = ''
      return true
    elseif M.cmd_t.mode then
      if not is_enter_key then
        local is_valid_key = (c <= 255)        
        if is_valid_key then 
          M.cmd_t.str = M.cmd_t.str .. string.char(c)
        end
      end
      if is_enter_key or M.is_hotkey(M.cmd_t.str) then
        local cmd_str = M.cmd_t.str
        local active_window = M.active_window
        M.dbg_str = M.dbg_str .. "active=" .. active_window  .. "cmd_str='" .. cmd_str .. "'\n"
        if M.all_windows[active_window].window_specific_commands[cmd_str] then
          M.dbg_str = M.dbg_str .. "in\n"
          local cmd_function = M.all_windows[active_window].window_specific_commands[cmd_str] 
          cmd_function()
        elseif M[M.cmd_t.str] then -- common text_box command 
          M[M.cmd_t.str]()
        end
        M.cmd_t.str = ''
      end
      return true
    end
    return false
  end


  M.banner_struct = {mode = true}
  function M.banner(c)
    local is_enter_key = (c == 10)
    local is_backspace_key  = (c == 8) or (c == 127)
    local ch = is_valid_key and string.char(c) or ''
    local ch_banner = ch
    if is_enter_key then
      ch_banner = '<cr>'
    elseif is_backspace_key then
      ch_banner = '<bs>'
    end
    local banner = ""
    if M.cmd_t.mode then
      banner = "cmd: " .. M.cmd_t.str
    else
      local maxx, maxy = M.getmaxyx()
      banner = "Enter Ctrl-Q to quit, '" .. ch_banner  .. "' (" .. tostring(c)  ..  '), size= ' .. tostring(maxx) .. 'x' .. tostring(maxy)
    end
    return banner
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


