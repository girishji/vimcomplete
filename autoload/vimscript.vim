vim9script

def Prefix(): list<any>
    var type = ''
    var prefix = ''
    var startcol = -1
    var line = getline('.')->strpart(0, col('.') - 1)
    var MatchStr = (pat) => { 
	prefix = line->matchstr(pat)
	startcol = col('.') - prefix->len()
	return prefix != ''
    }
    var kind = ''
    if MatchStr('\v-\>\zs\k+$')
	type = 'function'
	kind = 'f'
    elseif MatchStr('\v(\A+:|^:)\zs\k+$')
	type = 'command'
	kind = 'c'
    elseif MatchStr('\v(\A+\&|^\&)\zs\k+$')
	type = 'option'
	kind = 'o'
    elseif MatchStr('\v(\A+\$|^\$)\zs\k+$')
	type = 'environment'
	kind = 'e'
    elseif MatchStr('\v(\A+\zs\a:|^\a:)\k+$')
	type = 'var'
	kind = 'v'
    else
	var matches = line->matchlist('\v<(\a+)!{0,1}\s+(\k+)$')
	# autocmd, augroup, highlight, map, etc.
	if matches != [] && matches[1] != '' && matches[2] != ''
	    type = 'cmdline'
	    prefix = $'{matches[1]} {matches[2]}'
	    kind = 'V'
	    startcol = col('.') - matches[2]->len()
	    var items = prefix->getcompletion(type)
	    if items == []
		[prefix, type, kind] = ['', '', '']
	    endif
	endif
    endif
    if type == ''
	# last resort, look for function names
	prefix = line->matchstr('\k\+$')
	startcol = col('.') - prefix->len()
	[type, kind] = prefix->len() > 1 ? ['function', 'f'] : ['', '']
    endif
    return [prefix, type, kind, startcol]
enddef

export def Completor(findstart: number, base: string): any
    if findstart == 2
	return 1
    endif
    var [prefix, type, kind, startcol] = Prefix()
    if findstart == 1
	if type == ''
	    return -2
	endif
	return startcol
    endif

    var items = prefix->getcompletion(type)
    if kind != 'V'
	items = items->copy()->filter((_, v) => v =~# $'\v^{prefix}') +
	    items->copy()->filter((_, v) => v !~# $'\v^{prefix}')
    endif
    var citems = []
    for item in items
	citems->add({
	    word: item,
	    kind: kind,
	})
    endfor
    return citems
enddef

import '../autoload/completor.vim'
completor.Register('vimscript', Completor, ['vim'], 11)
