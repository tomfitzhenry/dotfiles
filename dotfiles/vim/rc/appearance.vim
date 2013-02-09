colorscheme elflord

set number
set list
set linebreak
set showbreak=>>

" Highlight merge markers
highlight MergeMarker guibg=red ctermbg=red
match MergeMarker /^[<=>]\{7\}.*$/
