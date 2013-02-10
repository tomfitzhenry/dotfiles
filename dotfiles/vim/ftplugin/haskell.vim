map Hc :GhcModCheck<CR> :GhcModLint<CR>

map Ht :GhcModType<CR>
map Hi :GhcModTypeInsert<CR>
map Hx :GhcModTypeClear<CR>

map Hr :!runhaskell %<CR>

set wildignore+=cabal-dev,dist

map Hu :PromptVimTmuxCommand<CR>cabal-dev install --enable-test<CR>
map Hs :PromptVimTmuxCommand<CR>cabal-dev ghci<CR>

let g:syntastic_haskell_checker_args = '--ghcOpt="-fno-code" --hlintOpt="--language=XmlSyntax --ignore=Eta reduce"'
