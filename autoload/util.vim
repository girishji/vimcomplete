vim9script

def WhitespaceOnly(): bool
    return strpart(getline('.'), col('.') - 2, 1) =~ '^\s*$'
enddef

import autoload '../autoload/vsnip.vim'
def Vsnip(): bool
    return (!vsnip.options->has_key('enable') || vsnip.options.enable) && exists('*vsnip#jumpable')
enddef

def VCCleverTab(): string
    if Vsnip()
	return pumvisible() ? "\<c-n>" : vsnip#jumpable(1) ? "\<Plug>(vsnip-jump-next)" : WhitespaceOnly() ? "\<tab>" : "\<c-n>"
    endif
    return pumvisible() ? "\<c-n>" : WhitespaceOnly() ? "\<tab>" : "\<c-n>"
enddef

def VCCleverSTab(): string
    if Vsnip()
	return pumvisible() ? "\<c-p>" : vsnip#jumpable(-1) ? "\<Plug>(vsnip-jump-prev)" : WhitespaceOnly() ? "\<s-tab>" : "\<c-p>"
    endif
    return pumvisible() ? "\<c-p>" : WhitespaceOnly() ? "\<s-tab>" : "\<c-p>"
enddef

export def TabEnable()
    if !get(g:, 'vimcomplete_tab_enable')
	return
    endif
    iunmap <silent> <tab>
    iunmap <silent> <s-tab>
    inoremap <expr> <tab>   VCCleverTab()
    snoremap <expr> <tab>   VCCleverTab()
    inoremap <expr> <S-Tab> VCCleverSTab()
    snoremap <expr> <S-Tab> VCCleverSTab()
enddef

