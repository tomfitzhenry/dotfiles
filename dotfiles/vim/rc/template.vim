" After loading a template, move the cursor to <+CURSOR+>:
autocmd User plugin-template-loaded
    \    if search('<+CURSOR+>')
    \  |   execute 'normal! "_da>'
    \  | endif
