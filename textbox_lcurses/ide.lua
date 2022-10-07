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

local textbox = require'textbox'
local banner  = require'textbox_banner'
local dirtree = require'textbox_dirtree'
local editor  = require'textbox_editor'

function ide()
  textbox.start()
  banner.new({height =  1, width = 137, starty =  0, startx =  0, hasborder = false, color_pair = textbox.color.black_on_white})
  dirtree.new({height = 40, width =  35, starty =  1, startx =  0, hasborder = true,  color_pair = textbox.color.black_on_white})
  editor.new({height = 30, width = 100, starty =  1, startx = 35, hasborder = true,  color_pair = textbox.color.white_on_black, active = true })
  textbox.new({name = 'status',  height = 10, width = 100, starty = 31, startx = 35, hasborder = true,  color_pair = textbox.color.magenta_on_black})

  local txt = ''

  while not textbox.quit() do
    textbox.print('status', textbox.cmd.dbg_str)
    dirtree.print()
    banner.print()
    editor.print(txt)

    if textbox.cmd.getch() then
      if textbox.cmd.is_backspace_key then
        txt = txt:sub(1, -2)
      elseif textbox.cmd.ch then
        txt = txt .. textbox.cmd.ch
      end
    end

  end -- while
end -- ide

xpcall(ide, textbox.err)

