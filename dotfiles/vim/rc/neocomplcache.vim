" https://github.com/Shougo/neocomplcache

" neocomplcache is too slow to be enabled on everything
"let g:neocomplcache_enable_at_startup = 1

inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
