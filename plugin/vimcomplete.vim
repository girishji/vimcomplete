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
        if get(g:, 'vimcomplete_noname_buf_enable', true)
            autocmd BufNewFile * completor.Enable()

            if &filetype == ""
                # Special case for noname buffers.
                completor.Enable()
            endif
        endif

        if ftypes->empty()
            autocmd BufReadPost * completor.Enable()
            g:vimcomplete_noname_buf_enable = true

            # Enable for the current buffer, but only if it's not a noname buffer.
            if &filetype != ""
                completor.Enable()
            endif
        else
            # New buffers with matching file type will start with
            # completion enabled.
            exec $'autocmd FileType {ftypes->join(",")} completor.Enable()'

            # Enable for the current buffer if it has a
            # matching file type.
            if index(ftypes, &filetype) >= 0
                completor.Enable()
            endif
        endif
    augroup END
enddef

command! -nargs=* -complete=filetype VimCompleteEnable VimCompEnable(<q-args>)
command! -nargs=0 VimCompleteDisable completor.Disable() | g:vimcomplete_noname_buf_enable = false
command! -nargs=0 VimCompleteCompletors completor.ShowCompletors()

augroup VimcompleteAutoCmds | autocmd!
    if get(g:, 'vimcomplete_enable_by_default', true)
        autocmd VimEnter * VimCompEnable("")
    endif
augroup END

if exists('#User#VimCompleteLoaded')
    :au VimEnter * doau <nomodeline> User VimCompleteLoaded
endif

# filetype detection is needed for this plugin to work
filetype plugin on
