vim9script

# Interface to https://github.com/yegappan/lsp through omnifunc

export def Completor(findstart: number, base: string): any
    if !exists('*g:LspOmniFunc') || &omnifunc != 'g:LspOmniFunc'
	return -2 # cancel but stay in completion mode
    endif
    return g:LspOmniFunc(findstart, base)
enddef

import '../autoload/completor.vim'
# completor.Register('lsp', Completor, ['*'], 11)
