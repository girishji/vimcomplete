vim9script

# Interface to hrsh7th/vim-vsnip

def Pattern(abbr: string): string
    var chars = escape(abbr, '\/?')->split('\zs')
    var chars_pattern = '\%(\V' .. chars->join('\m\|\V') .. '\m\)'
    var separator = chars[0] =~ '\a' ? '\<' : ''
    return $'{separator}\V{chars[0]}\m{chars_pattern}*$'
enddef

def GetCandidates(line: string): list<dict<any>>
    var citems = []
    for item in vsnip#get_complete_items(bufnr('%'))
	if line->matchstr(Pattern(item.abbr)) == ''
	    continue
	endif
	item.kind = 'S'
	citems->add(item)
    endfor
    return citems
enddef

def GetItems(): dict<any>
    var line = getline('.')->strpart(0, col('.') - 1)
    var items = GetCandidates(line)
    var prefix = line->matchstr('\S\+$')
    if prefix->empty() || items->empty()
	return { startcol: -2, items: [] }
    endif
    var filtered = items->copy()->filter((_, v) => v.abbr[0] ==# prefix[0])
    var startcol = col('.') - prefix->strlen()
    if !filtered->empty()
	return { startcol: startcol, items: filtered }
    endif
    var kwprefix = line->matchstr('\k\+$')
    if kwprefix->empty()
	return { startcol: startcol, items: items }
    endif
    filtered = items->copy()->filter((_, v) => v.abbr =~ '^\k')
    if !filtered->empty()
	return { startcol: col('.') - kwprefix->strlen(), items: filtered }
    endif
    return { startcol: startcol, items: items }
enddef

export def Completor(findstart: number, base: string): any
    if findstart == 2
	return 1
    endif
    if !exists('*vsnip#get_complete_items')
	return -2
    endif
    var citems = GetItems()
    if findstart == 1
	return citems.startcol
    endif

    citems.items->sort((v1, v2) => {
	var w1 = v1.abbr
	var w2 = v2.abbr
	if w1->len() < w2->len()
	    return -1
	elseif w1->len() == w2->len()
	    return w1 < w2 ? 1 : -1
	else
	    return 1
	endif
    })
    return citems.items
enddef

import '../autoload/completor.vim'
completor.Register('snippet', Completor, ['*'], 9)
