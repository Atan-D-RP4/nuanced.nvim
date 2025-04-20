return {
  'lervag/vimtex',
  ft = 'tex',
  -- tag = "v2.15", -- uncomment to pin to a specific release
  init = function()
    -- VimTeX configuration goes here, e.g.
    vim.g.vimtex_view_method = 'general'
    vim.g.vimtex_view_general_viewer = 'wslview'
    vim.g.vimtex_compiler_latexmk = {
      aux_dir = 'build',
      options = {
        '-pdf',
        '-shell-escape',
        '-verbose',
        '-file-line-error',
        -- '-synctex=1',
        '-interaction=nonstopmode',
      },
    }
  end,
}
