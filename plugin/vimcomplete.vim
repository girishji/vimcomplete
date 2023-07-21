if !has('vim9script') ||  v:version < 900
  " Needs Vim version 9.0 and above
  finish
endif

vim9script

# Async completion plugin for Vim

g:loaded_vimcomplete = true

import autoload '../autoload/completor.vim'
command! -nargs=0 VimCompleteEnable call completor.Enable()
command! -nargs=0 VimCompleteDisable call completor.Disable()
command! -nargs=0 VimCompleteCompletors call completor.ShowCompletors()

if exists('#VimCompleteLoaded#User')
    :doautocmd <nomodeline> VimCompleteLoaded User
endif

# augroup ICompAutocmds | autocmd!
#     autocmd BufEnter,BufReadPost * call completor.ChooseCompletors()
#     autocmd FileType,BufEnter,TabEnter * call ICompleteInit()
# augroup END


# # Set LSP plugin options from 'opts'.
# def g:LspOptionsSet(opts: dict<any>)
#   options.OptionsSet(opts)
# enddef

# g:icompleteEnableFt = ['*']

# var icompleteEnabled = false

# def ICompleteInit()
#     if &bt != '' || icompleteEnabled
# 	return
#     endif
#     if g:icompleteEnableFt->get(&ft, 0) != 0 || g:icompleteEnableFt->get('*', 0) != 0
# 	ICompleteEnable()
#     endif
#     icompleteEnabled = true
# enddef

# augroup ICompleteAutocmds | au!
#     autocmd FileType * call ICompleteInit()
#     autocmd BufEnter * call ICompleteInit()
#     autocmd TabEnter * call ICompleteInit()
# augroup END
