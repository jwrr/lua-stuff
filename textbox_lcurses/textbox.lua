
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
  M.curses  = curses
  M.lfs     = require'lfs'
  M.stringx = require'pl.stringx'
  M.utils   = require'pl.utils'
  M.dbg     = require"textbox_dbg"
  M.input   = require'textbox_input'
  M.input.init(M)
  M.color   = require'textbox_color'
  M.color.init(M)
  M.keys   = require'textbox_keys'
  
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


  function M.setmaxyx(maxy, maxx)
    M.maxy = maxy
    M.maxx = maxx
  end


  function M.getmaxyx(wname)
    if wname then
      local maxy = M.all_windows[wname].height
      local maxx = M.all_windows[wname].width
      return maxy, maxx
    end
    return M.maxy, M.maxx
  end


  function M.min(a, b)
    return (a < b) and a or b
  end


  function M.max(a, b)
    return (a > b) and a or b
  end


  function M.lpad(s, len)
    return string.rep(" ", len - #s) .. s
  end
  

  function M.rpad(s, len)
    return s .. string.rep(" ", len - #s)
  end

  
  function M.ltrim(s)
    return string.gsub(s, '^%s*', '')
  end


  function M.rtrim(s)
    return string.gsub(s, '%s*$', '')
  end
  
  
  function M.get_whitespace(s)
    if s and #s > 0 then
      return string.match(s, '^(%s*)') or ''
    end
    return ''
  end


  function M.starts_with(haystack, needle)
    if haystack and #haystack > 0 then
      if not string.find(needle, '^', 1, true) then
        needle = '^' .. needle
      end
      return not (string.match(haystack, needle) == nil)
    end
    return false
  end


  function M.replace_char(pos, s, ch)
    return string.sub(s, 1, pos-1) .. ch .. string.sub(s, pos+1)
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
      M.color.set_color_pair(name, this.color_pair)
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
      M.color.set_color_pair(name, this.color_pair)
    end
    this.win:wbkgd(curses.color_pair(this.color_pair))
    if this.filename then
      this.lines = M.utils.readlines(this.filename)
    end

  end


  function M.resize_windows(force)
    local stdscr = M.stdscr
    local prev_maxy, prev_maxx = M.getmaxyx()
    local maxy, maxx = stdscr:getmaxyx()
    if  maxy ~= prev_maxy or maxx ~= prev_maxx or force then
      M.setmaxyx(maxy, maxx)
      
      if M.all_windows['nav'].hidden then
        M.update({name = "banner", height =  1, starty =  0, startx =  0,      width = maxx})
        M.update({name = "editor", starty =  1, startx =  0, width = maxx, height = maxy - 11})
        M.update({name = "status", height = 10, startx =  0, width = maxx, starty = maxy - 10})
        -- M.update({name = "nav",    width =  0, starty =  0, startx =  0,   height = 0})
      else
        M.update({name = "banner", height =  1, starty =  0, startx =  0,      width = maxx})
        M.update({name = "editor", starty =  1, startx = 35, width = maxx - 36, height = maxy - 11})
        M.update({name = "status", height = 10, startx = 35, width = maxx - 36, starty = maxy - 10})
        M.update({name = "nav",    width =  35, starty =  1, startx =  0,   height = maxy-1})
      end

    end
    return maxy, maxx
  end

  M.color_normal   = M.color.white_on_black
  M.color_selected = M.color.black_on_white

  function M.refresh(name)
    local this = M.all_windows[name]
    if not this.hidden then
      if this.hasborder then
        local box_name = name .. '_box'
        local color = M.white_on_black
        if M.active_window == name then
          M.color.set_color_pair(box_name, M.color.red_on_black)
        else
          M.color.set_color_pair(box_name, M.color.white_on_black)
        end
        M.all_windows[box_name].win:box(0, 0)
        M.all_windows[box_name].win:refresh()
      end
      this.win:refresh()
    end
  end


  function M.refresh_all()
    for k,v in ipairs(M.all_windows) do
      M.refresh(k)
    end
  end


  function M.save_file_from_table(filename, lines)
    filename = filename or M.filename
    local lines = lines or M.lines
    local f = io.open(filename, 'w')
    for _,line in ipairs(lines) do
      f:write(line .. '\n')
    end
    f:close()
  end


  function M.read_file_into_table(t, filename)
    filename = filename or M.filename
    t.filename = filename
    M.dbg.print('filename=' ..  filename)

    local lines = {}
    for line in io.lines(filename) do
      table.insert(lines, line)
    end
    t.lines = lines
    t.line_number = 1
    t.column = 1
  end


  function M.num_usable_lines(wname)
    local maxy, maxx = M.getmaxyx(wname)
    return M.max(maxy-2, 0)
  end


  function M.align_screen_lines(t)
    t.cfg = t.cfg or {}
    t.cfg.lines_from_top = t.cfg.lines_from_top or 7
    t.cfg.lines_from_bot = t.cfg.lines_from_bot or 10
    t.cfg.keep_centered  = t.cfg.keep_centered or false

    t.screen_first_line = t.screen_first_line or 1
    t.screen_last_line = t.screen_last_line or #t.lines or 0

    local maxy = M.num_usable_lines(t.wname)
    local delta_from_top = t.line_number - t.screen_first_line
    t.screen_last_line = M.min(t.screen_first_line + maxy - 1, #t.lines)
    local delta_from_bot = t.screen_last_line - t.line_number
    if t.cfg.keep_centered then
      local half_screen = math.floor(maxy / 2)
      t.screen_first_line = M.max(t.line_number - half_screen, 1)
    elseif delta_from_top < t.cfg.lines_from_top then
      t.screen_first_line = M.max(t.line_number - t.cfg.lines_from_top, 1)
    elseif delta_from_bot < t.cfg.lines_from_bot then
      t.actual_lines_from_top = M.max(maxy - t.cfg.lines_from_bot, 0)
      t.screen_first_line = M.max(t.line_number - t.actual_lines_from_top, 1)
    end
    t.screen_last_line = M.min(t.screen_first_line + maxy - 1, #t.lines)
    if t.screen_last_line == #t.lines then
      t.screen_first_line = M.max(t.screen_last_line - maxy + 1, 1)
    end
    M.dbg.print("lnum="..tostring(t.line_number)..' first='..tostring(t.screen_first_line)..' last='..tostring(screen_last_line))
  end


  function M.print_lines2(t,  refresh)
    M.align_screen_lines(t)
    refresh = refresh or false
    local this = M.all_windows[t.wname]
    local txt_width = this.txt_width - 1
    this.win:move(0,0)
    local show_line_numbers = t.cfg and t.cfg.show_line_numbers or false
    local lnum_len = string.len(tostring(screen_last_line)) + 1
    t.line_number_len = lnum_len + 4

    t.select_first_line = t.select_first_line or 0
    t.select_last_line = t.select_last_line or 0

    M.dbg.print("line2"..tostring(t.select_first_line)..' '..tostring(t.select_last_line))
    for i=t.screen_first_line,t.screen_last_line do
      line1 = t.lines[i]
      local line = M.stringx.rstrip(line1, "\n\r")
      local has_eol = (line ~= line1)
      local is_lastline = (i == #t.lines)
      if show_line_numbers then
        this.win:addstr('  ' .. M.lpad(tostring(i), lnum_len) .. '  ')
      end
      line = M.stringx.shorten(line, txt_width-t.line_number_len)
      
      local line_is_selected = (t.select_first_line <= i) and (i <= t.select_last_line)
      if line_is_selected then
        local color = t.cfg.color_selected or M.color_selected or M.color.black_on_white
        M.color.set_color_pair(t.wname, color)
        M.dbg.print("is_selected: line="..tostring(i).." color="..tostring(color).." wname="..t.wname)
      end
      this.win:addstr(line)
      if line_is_selected then
        local color = t.cfg.color_normal or M.color_normal or M.color.white_on_black
        M.color.set_color_pair(t.wname, color)
        M.dbg.print("is_selectedxx: line="..tostring(i).." color="..tostring(color).." wname="..t.wname)
      end
      if has_eol or not is_lastline then
        this.win:addstr("\n")
      end
    end
    this.win:clrtobot()
    if refresh then
      M.refresh(t.wname)
    end
  end

  
  function M.print_lines(wname, lines, no_refresh, screen_first_line, screen_last_line)
    no_refresh = no_refresh or false
    screen_first_line = screen_first_line or 1
    screen_last_line = screen_last_line or #lines or 0
    local refresh = not no_refresh
    local this = M.all_windows[wname]
    local txt_width = this.txt_width - 1
    this.win:move(0,0)
    M.dbg.print("in print_lines: wname=".. wname  .. " first="..tostring(screen_first_line)..' last='..tostring(screen_last_line))
    for i=screen_first_line,screen_last_line do
      line1 = lines[i]
      local line = M.stringx.rstrip(line1, "\n\r")
      local has_eol = (line ~= line1)
      local is_lastline = (i == #lines)
      line = M.stringx.shorten(line, txt_width)
      if has_eol or not is_lastline then
        line = line .. "\n"
      end
      this.win:addstr(line)
    end
    this.win:clrtobot()
    if refresh then
      M.refresh(wname)
    end
  end
  
  
  function M.moveto(t, y, x)
    local this = M.all_windows[t.wname]
    local ln_len = t.line_number_len or 0
    this.win:move(y, x + ln_len)
  end


  function M.print(name, s, action)
    M.print_lines(name, M.stringx.splitlines(s, true), action)
  end


  function M.quit(force_quit)
    force_quit = force_quit or false
    M.force_quit = M.force_quit or force_quit
    if M.input.is_quit_key or M.force_quit then
      curses.endwin()
      return true
    end
    return false
  end


  M.txt = ''

  function M.getchar()
    if M.input.getch() then
      if M.input.is_backspace_key then
        M.txt = M.txt:sub(1, -2)
      elseif M.input.ch then
        M.txt = M.txt .. M.input.ch
      end
    end
    M.resize_windows()
    return not M.quit()
  end


  -- To display Lua errors, we must close curses to return to
  -- normal terminal mode, and then write the error to stdout.
  function M.err(err)
    curses.endwin()
    print "Caught an error:"
    print(debug.traceback(err, 2))
    os.exit(2)
  end




  function M.movey(t, delta_y)
    delta_y = delta_y or 0
    local ln1 = t.line_number
    if delta_y ~= 0 then
      local ln = t.line_number + delta_y
      ln = M.max(ln, 1)
      t.line_number = M.min(ln, #t.lines)
    end
    local success = t.line_number ~= ln1
    return success
  end


  function M.colmax(t, line_number)
    line_number = line_number or t.line_number
    return #t.lines[t.line_number] + 1
  end


  function M.movex(t, delta_x)
    delta_x = delta_x or 0
    if delta_x == 0 then return  end
    local col1 = t.column
    local ln1 = t.line_number
    local col = M.min(t.column, M.colmax(t))
    col = col + delta_x
    if delta_x < 0 then
      while (col < 1) and t.movey(-1) do
        col = M.colmax(t) + col -- col is negative
      end
    else
      local colmax = M.colmax(t)
      while (col > colmax) and t.movey(1) do
        col = colmax - col
        colmax = M.colmax(t)
      end
    end
    col = M.max(col, 1)
    t.column = M.min(col, M.colmax(t))
    local success = (t.column ~= col1) or (t.line_number ~= ln1)
    return success
  end
  
  function M.goto_line(t, ln)
    t.line_number = ln or #t.lines
  end
  

return M


