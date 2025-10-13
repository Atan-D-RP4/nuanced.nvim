local map = require('nuance.core.utils').map
map('n', 'gl', '<Plug>(neorg.esupports.hop.hop-link)', '[ft] [neorg] Jump to Link')
map('n', '<,', '<Plug>(neorg.promo.demote)', '[ft] [neorg] Demote Object (Non-Recursive)')
map('n', '>.', '<Plug>(neorg.promo.promote)', '[ft] [neorg] Promote Object (Non-Recursive)')
map('v', '<', '<Plug>(neorg.promo.demote.range)gv', '[ft] [neorg] Demote Objects in Range')
map('v', '>', '<Plug>(neorg.promo.promote.range)gv', '[ft] [neorg] Promote Objects in Range')
map('n', '>>', '<Plug>(neorg.promo.promote.nested)', '[ft] [neorg] Promote Object (Recursive)')
map('n', '<<', '<Plug>(neorg.promo.demote.nested)', '[ft] [neorg] Demote Object (Recursive)')
