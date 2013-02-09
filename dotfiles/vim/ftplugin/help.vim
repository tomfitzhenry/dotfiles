" http://vim.wikia.com/wiki/Learn_to_use_help#Simplify_help_navigation
nnoremap <buffer> <CR> <C-]>
nnoremap <buffer> <BS> <C-T>
nnoremap <buffer> o /'\l\{2,\}'<CR>
" This causes a ``No mapping found'' error beyond by understanding and level of care
"nnoremap <buffer> O ?'\l\{2,\}'<CR>
nnoremap <buffer> s /\|\zs\S\+\ze\|<CR>
"nnoremap <buffer> S ?\|\zs\S\+\ze\|<CR>
