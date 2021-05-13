vim.g.neomux_start_term_map = "<Leader>tt"
vim.g.neomux_exit_term_mode_map = "<C-space>"
vim.g.neomux_start_term_split_map = "<Leader>ts"
vim.g.neomux_start_term_vsplit_map = "<Leader>tv"

if vim.fn.has('nvim') then
  vim.api.nvim_set_var('$GIT_EDITOR', 'nvr -cc split --remote-wait')
end

