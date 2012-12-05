colorscheme elflord
if has("syntax")
	syntax on
endif

set number
set showcmd
set listchars=tab:`\ ,trail:.
set list "list mode displays all your special characters, define them above
set linebreak
set showbreak=>>

" Highlight merge markers
highlight MergeMarker guibg=red ctermbg=red
match MergeMarker /^[<=>]\{7\}.*$/
