
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

  local tb = require'textbox'
  local win_name = 'banner'

  function M.new(cfg)
    cfg['name'] = win_name
    tb.new(cfg)
  end


  M.banner_struct = {visible = true}

  function M.tostring()
    local c = tb.input.c
    local ch_banner = tb.input.ch or "r"
    local is_enter_key = tb.input.is_enter_key
    local is_backspace_key = tb.input.is_backspace_key
    local is_valid_key = tb.input.is_valid_key 
    if is_enter_key then
      ch_banner = '<cr>'
    elseif is_backspace_key then
      ch_banner = '<bs>'
    end
    local banner_str = ""
    if tb.input.in_progress then
      banner_str = "input: " .. tb.input.escape_sequence
    else
      local stdscr = M.stdscr
      local maxx, maxy = tb.getmaxyx()
      banner_str = "Enter Ctrl-Q to quit, '" .. ch_banner  .. "' (" .. tostring(c)  ..  '), size= ' .. tostring(maxx) .. 'x' .. tostring(maxy)
    end
    return banner_str
  end


  function M.print(str)
    str = str or M.tostring(tb.input.c)
    tb.print(win_name, str)
  end

return M

