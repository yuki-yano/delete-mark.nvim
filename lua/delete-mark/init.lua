local render = require('delete-mark.core').render
local toggle = require('delete-mark.core').toggle
local eject = require('delete-mark.core').eject

local M = {}
M.ns = vim.api.nvim_create_namespace('delete_mark')

---@type table<number, table<number, table<number, number, number>>>
M.extmarks = {}

---@class delete-mark.Opts
---@field public mappings delete-mark.Mappings
---@field public highlight delete-mark.Highlight
---@field public sign string
---@field public tag delete-mark.Tag
---@field public priority number

---@class delete-mark.Mappings
---@field public normal string
---@field public insert string
---@field public visual string

---@class delete-mark.Highlight
---@field public mark HighlightDefinitionMap
---@field public sign HighlightDefinitionMap
---@field public between HighlightDefinitionMap

---@class delete-mark.Tag
---@field public open string
---@field public close string

local default_opts = {
  mappings = {
    normal = '<C-e>',
    insert = '<C-e>',
    visual = '<C-e>',
  },
  events = { 'TextChanged', 'BufRead', 'WinEnter' },
  highlight = {
    mark = { link = 'Error' },
    sign = { link = 'Error' },
    between = { link = 'DiffDelete' },
  },
  sign = 'X',
  tag = {
    open = 'DELETE!: open',
    close = 'DELETE!: close',
  },
  priority = 1000,
}

M.opts = {}

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend('force', default_opts, opts or {})

  vim.api.nvim_set_hl(0, 'DeleteMark', opts.highlight.mark or default_opts.highlight.mark)
  vim.api.nvim_set_hl(0, 'DeleteMarkBetween', opts.highlight.between or default_opts.highlight.between)
  vim.api.nvim_set_hl(0, 'DeleteMarkSign', opts.highlight.sign or default_opts.highlight.sign)
  vim.cmd([[sign define delete_mark text=]] .. M.opts.sign .. [[ texthl=DeleteMark]])

  vim.api.nvim_create_user_command('ToggleDeleteMark', toggle, { range = true })
  vim.api.nvim_create_user_command('EjectDeleteMark', eject, { range = '%' })
  vim.api.nvim_create_user_command('ResetDeleteMark', function()
    M.extmarks = {}
    render()
  end, { range = '%' })

  if M.opts.mappings.normal then
    vim.keymap.set({ 'n' }, M.opts.mappings.normal, ':ToggleDeleteMark<CR>', { silent = true })
  end
  if M.opts.mappings.insert then
    vim.keymap.set({ 'i' }, M.opts.mappings.insert, '<Cmd>ToggleDeleteMark<CR>')
  end
  if M.opts.mappings.visual then
    vim.keymap.set({ 'v' }, M.opts.mappings.visual, ':ToggleDeleteMark<CR>', { silent = true })
  end

  if #M.opts.events > 0 then
    vim.api.nvim_create_autocmd(M.opts.events, {
      pattern = { '*' },
      callback = function()
        render()
      end,
    })
  end
end

return M
