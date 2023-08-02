vim9script

# Interface to https://github.com/yegappan/lsp through omnifunc

export var options: dict<any> = {
    enable: false,
    maxCount: 10,
    dup: true,
}

def Setup()
    var lspOpts = {
	useBufferCompletion: false,
	completionTextEdit: false,
	snippetSupport: true, # snippets from lsp server
	vsnipSupport: false,
	autoComplete: false,
    }
    if exists('*g:LspOptionsSet')
	g:LspOptionsSet(lspOpts)
    endif
enddef

autocmd User VimCompleteLoaded ++once call Setup()

export def Completor(findstart: number, base: string): any
    if !exists('*g:LspOmniFunc')
	return -2 # cancel but stay in completion mode
    endif
    var line = getline('.')->strpart(0, col('.') - 1)
    var prefix = line->matchstr('\k\+$')
    if prefix == ''
	return -2
    endif
    if findstart == 1
	var startcol = g:LspOmniFunc(findstart, base)
	return startcol < 0 ? startcol : startcol + 1
    elseif findstart == 2
	return !g:LspOmniCompletePending()
    endif
    var items = g:LspOmniFunc(findstart, base)
    items = items->slice(0, options.maxCount)
    if options.dup
	items->map((_, v) => v->extend({ dup: 1 }))
    endif
    return items
enddef

import '../autoload/completor.vim'
def Register()
    if !options->has_key('enable') || options.enable
	if !options->has_key('filetypes')
	    options.filetypes = []
	endif
	if options.filetypes->index(&ft) == -1
	    options.filetypes->add(&ft)
	    completor.Register('lsp', Completor, options.filetypes,  options->get('priority', 8))
	endif
    endif
enddef
autocmd User LspAttached call Register()
