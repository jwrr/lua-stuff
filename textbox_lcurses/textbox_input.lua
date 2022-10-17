
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

  M.all_windows = {}
  M.history = {}
  M.history_idx = 0;

  function M.init(tb)
    M.tb = tb
  end


  function M.bind_seq(wname, seq, func, description)
    description = description or ""
    M.all_windows[wname] = M.all_windows[wname] or {}
    M.all_windows[wname].window_specific_commands = M.all_windows[wname].window_specific_commands or {}
    M.all_windows[wname].window_specific_command_description = M.all_windows[wname].window_specific_command_description or {}

    M.all_windows[wname].window_specific_commands[seq] = func
    M.all_windows[wname].window_specific_command_description[seq] = description
    M.tb.dbg.print("bind_seq: " .. wname .. " " .. seq)
  end


  function M.bind_key(wname, key, func, description)
    description = description or ""
    M.all_windows[wname] = M.all_windows[wname] or {}
    M.all_windows[wname].window_specific_commands = M.all_windows[wname].window_specific_commands or {}
    M.all_windows[wname].window_specific_command_description = M.all_windows[wname].window_specific_command_description or {}

    M.all_windows[wname].window_specific_commands[key] = func
    M.all_windows[wname].window_specific_command_description[key] = description
    M.tb.dbg.print("bind_key: " .. wname .. " " .. key)
  end


  function M.is_hotkey(str)
    return false
  end

  M.escape_sequence  = ''
  M.in_progress = false


  function M.handle_escape_sequence(active_window, c)
    local is_esc_key = (c == 27)
    local is_enter_key = (c == 10) or (c == 13)
    local is_backspace_key  = (c == 8) or (c == 127) or (c == 263)
    if is_esc_key then
      M.in_progress = not M.in_progress
      M.escape_sequence = ''
      return true
    elseif M.in_progress then
      if is_backspace_key then
        M.escape_sequence = M.escape_sequence:sub(1, -2)
      elseif not is_enter_key then
        local is_valid_key = (c <= 255)
        if is_valid_key and M.ch then
          M.escape_sequence = M.escape_sequence .. M.ch
        end
      end
      if is_enter_key or M.is_hotkey(M.escape_sequence) then
        local escape_sequence = M.escape_sequence or ''
        if escape_sequence == '' then
          escape_sequence = M.history[#M.history] or ''
        end
        M.tb.dbg.clear("active=" .. active_window  .. " escape_sequence='" .. escape_sequence)
        M.all_windows[active_window] = M.all_windows[active_window] or {}
        M.all_windows[active_window].window_specific_commands = M.all_windows[active_window].window_specific_commands or {}
        if M.all_windows[active_window].window_specific_commands[escape_sequence] then
          local input_function = M.all_windows[active_window].window_specific_commands[escape_sequence]
          M.tb.dbg.print("in " .. active_window .. '.' .. escape_sequence)
          input_function()
          M.history[#M.history+1] = escape_sequence
        elseif M[M.escape_sequence] then -- common text_box command
           M[M.escape_sequence]()
        end
        M.escape_sequence = ''
      end
      return true
    end
    return false
  end


  function M.handle_cmdkey(active_window, c)
    local is_esc_key = (c == 27)
    local is_enter_key = (c == 10) or (c == 13)
    local is_backspace_key  = (c == 8) or (c == 127) or (c == 263)

    M.all_windows[active_window] = M.all_windows[active_window] or {}
    M.all_windows[active_window].window_specific_commands = M.all_windows[active_window].window_specific_commands or {}
    if M.all_windows[active_window].window_specific_commands[c] then
      local input_function = M.all_windows[active_window].window_specific_commands[c]
      input_function()
      M.history[#M.history+1] = c
      return true
    end
    return false
  end


  function M.getch()
    local c = M.tb.stdscr:getch()
    M.c = c
    M.is_quit_key  = (c == 17)
    M.is_valid_key = (c <= 255)
    M.is_enter_key = (c == 10)
    M.is_backspace_key  = (c == 8) or (c == 127) or (c == 263)
    M.ch = M.is_valid_key and string.char(c) or ''
    M.in_escape_sequence = M.handle_escape_sequence(M.tb.active_window, c)
    if not M.in_escape_sequence then
      M.is_cmdkey = M.handle_cmdkey(M.tb.active_window, c)
    end
    return not M.in_escape_sequence and not M.is_cmdkey
  end

return M


