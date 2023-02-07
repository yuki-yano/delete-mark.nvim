# delete-mark.nvim

This plugin manipulates and highlights temporary comments that are scheduled for deletion.

## Usage

Call the setup function will default map to `<C-e>` or execute `ToggleDeleteMark`.

To delete comments, including inner code, execute `EjectDeleteMark`.

```lua
require('delete-mark').setup({
  -- opts
})
```

default opts:

```lua
{
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
}
```
