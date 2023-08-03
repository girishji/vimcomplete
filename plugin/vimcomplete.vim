if !has('vim9script') ||  v:version < 900
    " Needs Vim version 9.0 and above
    finish
endif

vim9script

# Async completion plugin for Vim

g:loaded_vimcomplete = true

import autoload '../autoload/completor.vim'
command! -nargs=0 VimCompleteEnable completor.Enable()
command! -nargs=0 VimCompleteDisable completor.Disable()
command! -nargs=0 VimCompleteCompletors completor.ShowCompletors()

if exists('#User#VimCompleteLoaded')
    :au VimEnter * doau <nomodeline> User VimCompleteLoaded
endif
