
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

  local textbox = require'textbox'

  M.wname = 'editor'

  function M.new(cfg)
    cfg['name'] = M.wname
    textbox.new(cfg)
    M.register_functions(M.wname)
  end

  M.txt = ''
  M.lines = {}
  M.linenumber = 1
  M.column = 1

  function M.print(txt)
    txt = txt or M.txt
    textbox.print(M.wname, txt)
  end


  function M.getchar()
    local is_text = textbox.input.getch()
    if is_text then
      if textbox.input.is_backspace_key then
        M.txt = M.txt:sub(1, -2)
      elseif textbox.input.ch then -- ch should always exist...but just in case
        M.lines[M.linenumber] = M.lines[M.linenumber] or ''
        local line = M.lines[M.linenumber]
        local append = #line < M.column
        local insert = #line >= M.column
        if append then
          M.lines[M.linenumber] = line .. textbox.input.ch
          M.column = M.column + #textbox.input.ch
        elseif insert then
          M.lines[M.linenumber] = line:sub(1,M.column) .. textbox.input.ch .. line:sub(M.column+1, #line)
          M.column = M.column + #textbox.input.ch
        end  
        
        M.txt = M.txt .. textbox.input.ch
      end
    end
    textbox.resize_windows()
    return not textbox.quit()
  end

-- ==========================================================================
-- ==========================================================================


  function M.open()
    local tmp_window = textbox.active_window
    textbox.active_window = "nav"
    textbox.refresh(tmp_window)
  end


  function M.quit()
    textbox.quit(true)
  end


  function M.register_functions(wname)
    textbox.input.register(wname, 'open',  M.open, "Open file for editing")
    textbox.input.register(wname, 'quit',  M.quit, "Quit")
  end


return M

