vim9script

# Interface to https://github.com/yegappan/lsp through omnifunc

# var ready: bool = false

var options: dict<any> = {
    MaxCount: 5,
}

export def Completor(findstart: number, base: string): any
    if !exists('*g:LspOmniFunc') || &omnifunc != 'g:LspOmniFunc'
	return -2 # cancel but stay in completion mode
    endif
    var line = getline('.')->strpart(0, col('.') - 1)
    var prefix = line->matchstr('\k\+$')
    if prefix == ''
	return -2
    endif
    if findstart == 1
	# ready = true
	return g:LspOmniFunc(findstart, base) + 1
    elseif findstart == 2
	return g:LspOmniCompletePending()
	# if ready
	#     ready = false
	#     return 0
	# else
	#     return 1
	# endif
    endif
    return g:LspOmniFunc(findstart, base)->slice(0, options.MaxCount + 1)
enddef

import '../autoload/completor.vim'
completor.Register('lsp', Completor, ['*'], 8)
