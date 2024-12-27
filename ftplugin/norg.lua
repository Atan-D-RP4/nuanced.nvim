local map = require('nuance.core.utils').map
map('n', 'gl', '<Plug>(neorg.esupports.hop.hop-link)', '[neorg] Jump to Link [c]')
map('n', '<,', '<Plug>(neorg.promo.demote)', '[neorg] Demote Object (Non-Recursive) [c]')
map('n', '>.', '<Plug>(neorg.promo.promote)', '[neorg] Promote Object (Non-Recursive) [c]')
map('v', '<', '<Plug>(neorg.promo.demote.range)gv', '[neorg] [c]')
map('v', '>', '<Plug>(neorg.promo.promote.range)gv', '[neorg] [c]')
map('n', '>>', '<Plug>(neorg.promo.promote.nested)', '[neorg] [c]')
map('n', '<<', '<Plug>(neorg.promo.demote.nested)', '[neorg] [c]')
vim.print('neorg.lua')
