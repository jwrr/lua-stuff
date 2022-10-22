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

local M = {}
  local tb = require'textbox'
  local banner  = require'textbox_banner'
  local dirtree = require'textbox_dirtree'
  local editor  = require'textbox_editor'

  function M.init_screen()
    tb.start()
    banner.new({height =  1, width = 137, starty =  0, startx =  0, hasborder = false, color_pair = tb.color.black_on_white})
    dirtree.new({height = 40, width =  35, starty =  1, startx =  0, hasborder = true,  color_pair = tb.color.black_on_white, hidden = true})
    editor.new({height = 30, width = 100, starty =  1, startx = 35, hasborder = true,  color_pair = tb.color.white_on_black, active = true})
    tb.new({name = 'status',  height = 10, width = 100, starty = 31, startx = 35, hasborder = true,  color_pair = tb.color.magenta_on_black})
    M.update_screen(true)
    tb.resize_windows(true)
    editor.moveto()
  end

  function M.update_screen(force)
    tb.resize_windows(false)
    force = force or false
    banner.print()
    dirtree.print(force)
    tb.print('status', tb.dbg.str)
    editor.print(force)
  end

  function M.ide()
    M.init_screen()
    while editor.on_keypress() do
      M.update_screen(true)
    end
  end

  xpcall(M.ide, tb.err)

return M

