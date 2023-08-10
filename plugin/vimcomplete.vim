if !has('vim9script') ||  v:version < 900
    " Needs Vim version 9.0 and above
    finish
endif

vim9script

# Async completion plugin for Vim

g:loaded_vimcomplete = true

import autoload '../autoload/completor.vim'

def VimCompEnable(filetypes: string)
    var ftypes = filetypes->split()
    # Plugins that define their own filetypes and sourced after this plugin
    # will not have the filetype available to verify. One way to verify, if
    # necessary, is by using getcompletion().
    augroup VimcompleteAutoCmds | autocmd!
	if ftypes->empty()
	    autocmd BufNewFile,BufReadPost * completor.Enable()
	    g:vimcomplete_noname_buf_enable = true
	else
	    exec $'autocmd FileType {ftypes->join(",")} completor.Enable()'
	endif
    augroup END
enddef

command! -nargs=* -complete=filetype VimCompleteEnable VimCompEnable(<q-args>)
command! -nargs=0 VimCompleteDisable completor.Disable() | g:vimcomplete_noname_buf_enable = false
command! -nargs=0 VimCompleteCompletors completor.ShowCompletors()

augroup VimcompleteAutoCmds | autocmd!
    autocmd BufNewFile,BufReadPost * completor.Enable()
augroup END

if exists('#User#VimCompleteLoaded')
    :au VimEnter * doau <nomodeline> User VimCompleteLoaded
endif

# filetype detection is needed for this plugin to work
filetype plugin on
