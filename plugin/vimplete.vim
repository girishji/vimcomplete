if !has('vim9script') ||  v:version < 900
  " Needs Vim version 9.0 and above
  finish
endif

vim9script

# Async completion plugin for Vim

g:loaded_icomplete = true

import autoload '../autoload/completor.vim'
command! -nargs=0 ICompleteEnable call completor.Enable()
command! -nargs=0 ICompleteDisable call completor.Disable()
command! -nargs=0 ICompleteCompletors call completor.ShowCompletors()

g:vimcomplete_tab_enable = 0

if g:vimcomplete_tab_enable
    def WhitespaceOnly(): bool
	return strpart(getline('.'), col('.') - 2, 1) =~ '^\s*$'
    enddef
    def VCCleverTab(): string
	if exists('*vsnip#jumpable')
	    return pumvisible() ? "\<c-n>" : vsnip#jumpable(1) ? "\<Plug>(vsnip-jump-next)" : WhitespaceOnly() ? "\<tab>" : "\<c-n>"
	endif
	return pumvisible() ? "\<c-n>" : WhitespaceOnly() ? "\<tab>" : "\<c-n>"
    enddef
    def VCCleverSTab(): string
	if exists('*vsnip#jumpable')
	    return pumvisible() ? "\<c-p>" : vsnip#jumpable(-1) ? "\<Plug>(vsnip-jump-prev)" : WhitespaceOnly() ? "\<s-tab>" : "\<c-p>"
	endif
	return pumvisible() ? "\<c-p>" : WhitespaceOnly() ? "\<s-tab>" : "\<c-p>"
    enddef
    autocmd FileType java,c,cpp,python
		\| iunmap <silent> <tab>
		\| iunmap <silent> <s-tab>
		\| inoremap <expr> <tab> VCCleverTab()
		\| snoremap <expr> <tab> VCCleverTab()
		\| inoremap <expr> <S-Tab> VCCleverSTab()
		\| snoremap <expr> <S-Tab> VCCleverSTab()
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
