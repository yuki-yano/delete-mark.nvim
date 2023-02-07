local M = {}

M.render = function()
  local opts = require('delete-mark').opts
  local ns = require('delete-mark').ns
  local extmarks = require('delete-mark').extmarks

  if not opts then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if not extmarks[bufnr] then
    extmarks[bufnr] = {}
  else
    for _, marks in ipairs(extmarks[bufnr]) do
      vim.api.nvim_buf_del_extmark(0, ns, marks[1])
      vim.api.nvim_buf_del_extmark(0, ns, marks[2])
      vim.api.nvim_buf_del_extmark(0, ns, marks[3])
    end
    extmarks[bufnr] = {}
  end

  local open_tag = opts.tag.open
  local close_tag = opts.tag.close
  local lines = vim.fn.getline(1, '$')
  for i, line in ipairs(lines) do
    if line:find(open_tag) then
      local open_line = nil
      local close_line = nil
      for j = i + 1, #lines do
        if lines[j]:find(close_tag) then
          open_line = i
          close_line = j
          break
        end
      end

      if open_line and close_line then
        local indent = vim.fn.indent(i)
        local open_mark = vim.api.nvim_buf_set_extmark(0, ns, open_line - 1, indent, {
          end_col = #lines[open_line],
          hl_eol = true,
          hl_group = 'DeleteMark',
          sign_text = opts.sign,
          sign_hl_group = 'DeleteMarkSign',
          priority = 100,
        })
        local between_mark = vim.api.nvim_buf_set_extmark(0, ns, open_line, 0, {
          end_row = close_line - 1,
          hl_eol = true,
          hl_group = 'DeleteMarkBetween',
          priority = 100,
        })
        local close_mark = vim.api.nvim_buf_set_extmark(0, ns, close_line - 1, indent, {
          end_col = #lines[close_line],
          hl_eol = true,
          hl_group = 'DeleteMark',
          sign_text = opts.sign,
          sign_hl_group = 'DeleteMarkSign',
          priority = 100,
        })
        table.insert(extmarks[bufnr], { open_mark, close_mark, between_mark })
      end
    end
  end
end

---@class delete-mark.toggle.Opts
---@field public line1 number
---@field public line2 number

---@param command_opts delete-mark.toggle.Opts
M.toggle = function(command_opts)
  local opts = require('delete-mark').opts
  local ns = require('delete-mark').ns
  local extmarks = require('delete-mark').extmarks

  if not opts then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()

  for i, marks in ipairs(extmarks[bufnr]) do
    local open_mark = vim.api.nvim_buf_get_extmark_by_id(0, ns, marks[1], { details = true })
    local close_mark = vim.api.nvim_buf_get_extmark_by_id(0, ns, marks[2], { details = true })
    if vim.fn.line('.') - 1 > open_mark[1] and vim.fn.line('.') - 1 < close_mark[1] then
      vim.api.nvim_buf_del_extmark(0, ns, marks[1])
      vim.api.nvim_buf_del_extmark(0, ns, marks[2])
      vim.api.nvim_buf_del_extmark(0, ns, marks[3])
      vim.fn.deletebufline(bufnr, close_mark[1] + 1)
      vim.fn.deletebufline(bufnr, open_mark[1] + 1)
      table.remove(extmarks[bufnr], i)
      return
    end
  end

  local indent = vim.fn.indent(command_opts.line1 or vim.fn.line('.'))
  local open_text =
    vim.fn.printf('%s%s', string.rep(' ', indent), vim.fn.printf(vim.o.commentstring, ' ' .. opts.tag.open))
  local open_line = command_opts.line1 or vim.fn.line('.')
  vim.fn.append(open_line - 1, open_text)
  local close_text =
    vim.fn.printf('%s%s', string.rep(' ', indent), vim.fn.printf(vim.o.commentstring, ' DELETE!: close'))
  local close_line = command_opts.line2 or vim.fn.line('.')
  vim.fn.append(close_line + 1, close_text)

  M.render()
end

---@class delete-mark.eject.Opts
---@field public line1 number
---@field public line2 number

---@param command_opts delete-mark.eject.Opts
M.eject = function(command_opts)
  local ns = require('delete-mark').ns
  local extmarks = require('delete-mark').extmarks

  local delete_ranges = {}
  local bufnr = vim.api.nvim_get_current_buf()
  if not extmarks[bufnr] then
    extmarks[bufnr] = {}
  end

  for _, marks in ipairs(extmarks[bufnr]) do
    local open_mark = vim.api.nvim_buf_get_extmark_by_id(0, ns, marks[1], { details = true })
    local close_mark = vim.api.nvim_buf_get_extmark_by_id(0, ns, marks[2], { details = true })
    if open_mark[1] > command_opts.line1 - 1 and close_mark[1] < command_opts.line2 - 1 then
      table.insert(delete_ranges, { open_mark[1] + 1, close_mark[1] + 1 })
    end
  end
  table.sort(delete_ranges, function(a, b)
    return a[1] > b[1]
  end)
  for _, range in ipairs(delete_ranges) do
    vim.fn.deletebufline(bufnr, range[1], range[2])
  end
end

return M
