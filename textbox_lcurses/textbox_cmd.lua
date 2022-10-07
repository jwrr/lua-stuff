
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
  M.dbg_str="cmd_dbg\n"


  function M.init(textbox)
    M.textbox = textbox
  end


  function M.register(wname, fname, func, description)
    description = description or ""
    M.all_windows[wname] = M.all_windows[wname] or {}
    M.all_windows[wname].window_specific_commands = M.all_windows[wname].window_specific_commands or {}
    M.all_windows[wname].window_specific_command_description = M.all_windows[wname].window_specific_command_description or {}

    M.all_windows[wname].window_specific_commands[fname] = func
    M.all_windows[wname].window_specific_command_description[fname] = description
    M.dbg_str = M.dbg_str .. "register: " .. wname .. " " .. fname .. "\n"
  end


  function M.is_hotkey(str)
    return false
  end

  M.cmd_str  = ''
  M.cmd_in_progress = false

  function M.cmd(active_window, c)
    local is_esc_key = (c == 27)
    local is_enter_key = (c == 10) or (c == 13)
    local is_backspace_key  = (c == 8) or (c == 127) or (c == 263)
    if is_esc_key then
      M.cmd_in_progress = not M.cmd_in_progress
      M.cmd_str = ''
      return true
    elseif M.cmd_in_progress then
      if is_backspace_key then
        M.cmd_str = M.cmd_str:sub(1, -2)
      elseif not is_enter_key then
        local is_valid_key = (c <= 255)
        if is_valid_key and M.ch then
          M.cmd_str = M.cmd_str .. M.ch
        end
      end
      if is_enter_key or M.is_hotkey(M.cmd_str) then
        local cmd_str = M.cmd_str
        if cmd_str == '' then
          cmd_str = M.history[#M.history]
        end
        M.dbg_str = M.dbg_str .. "active=" .. active_window  .. " cmd_str='" .. cmd_str .. "'\n"
        M.all_windows[active_window] = M.all_windows[active_window] or {}
        M.all_windows[active_window].window_specific_commands = M.all_windows[active_window].window_specific_commands or {}
        if M.all_windows[active_window].window_specific_commands[cmd_str] then
          local cmd_function = M.all_windows[active_window].window_specific_commands[cmd_str]
          M.dbg_str = M.dbg_str .. "in " .. active_window .. '.' .. cmd_str .. "\n"
          cmd_function()
          M.history[#M.history+1] = cmd_str
        elseif M[M.cmd_str] then -- common text_box command
           M[M.cmd_str]()
        end
        M.cmd_str = ''
      end
      return true
    end
    return false
  end


  function M.getch()
    local c = M.textbox.getch()
    M.c = c
    M.is_quit_key  = (c == 17)
    M.is_valid_key = (c <= 255)
    M.is_enter_key = (c == 10)
    M.is_backspace_key  = (c == 8) or (c == 127) or (c == 263)
    M.ch = M.is_valid_key and string.char(c) or ''
    M.in_escape_sequence = M.cmd(M.textbox.active_window, c)
    return not M.in_escape_sequence
  end

return M


