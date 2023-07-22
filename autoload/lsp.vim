vim9script

# Interface to https://github.com/yegappan/lsp through omnifunc

export var options: dict<any> = {
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
	return g:LspOmniFunc(findstart, base) + 1
    elseif findstart == 2
	return !g:LspOmniCompletePending()
    endif
    var items = g:LspOmniFunc(findstart, base)
    if !items->empty()
	items = items->slice(0, options.MaxCount + 1)
    endif
    return items
enddef
