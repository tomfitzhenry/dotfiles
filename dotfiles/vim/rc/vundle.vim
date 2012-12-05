" Adapted from https://github.com/gmarik/vundle
"
" < vimgor> Vim currently supports four ways of managing plugins: manual (deprecated), pathogen (simplest), VAM and Vundle (both more featureful)

set nocompatible
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

"Required
Bundle 'gmarik/vundle'

Bundle 'vim-scripts/template.vim'

Bundle 'Shougo/vimproc'

Bundle 'eagletmt/ghcmod-vim'
Bundle 'Twinside/vim-hoogle'
Bundle 'vim-scripts/haskell.vim'

Bundle 'rodjek/vim-puppet'

filetype plugin indent on
