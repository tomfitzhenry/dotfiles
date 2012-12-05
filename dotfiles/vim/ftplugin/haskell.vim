NeoComplCacheEnable

autocmd BufWritePost * GhcModCheckAndLintAsync

map hc :GhcModCheck<CR> :GhcModLint<CR>

map ht :GhcModType<CR>
map hi :GhcModTypeInsert<CR>
map hx :GhcModTypeClear<CR>

let g:ghcmod_ghc_options = ['-fno-warn-unused-binds']
let g:ghcmod_hlint_options = ['--ignore=Redundant $']

let &l:statusline = '%{empty(getqflist()) ? "[No Errors]" : "[Errors Found]"}' . (empty(&l:statusline) ? &statusline : &l:statusline)

map hr :!runhaskell %<CR>
