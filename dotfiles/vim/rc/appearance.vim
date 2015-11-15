colorscheme elflord

set list
set linebreak
set showbreak=>>

" Highlight merge markers
highlight MergeMarker guibg=red ctermbg=red
match MergeMarker /^[<=>]\{7\}.*$/

" remove scrollbar from macvim
set guioptions-=r
set guioptions-=L

let g:airline#extensions#tabline#enabled = 1
