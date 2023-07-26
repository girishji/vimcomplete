vim9script

# Interface to https://github.com/yegappan/lsp through omnifunc

export var options: dict<any> = {
    enable: false,
    maxCount: 10,
    dup: true,
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
	return g:LspOmniFunc(findstart, base) + 1
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
