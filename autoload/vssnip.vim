vim9script

var options: dict<any> = {
    fuzzy: false,
}

def Pattern(abbr: string): string
    var chars = escape(abbr, '\/?')->split('\zs')
    var chars_pattern = '\%(\V' .. chars->join('\m\|\V') .. '\m\)'
    var separator = chars[0] =~ '\a' ? '\<' : ''
    return $'{separator}\V{chars[0]}\m{chars_pattern}*$'
enddef

export def Completor(findstart: number, base: string): any
    if findstart == 2
	return 1
    endif
    if !exists('*vsnip#get_complete_items')
	return -2
    endif
    var line = getline('.')->strpart(0, col('.') - 1)
    if findstart == 1
	var prefix = line->matchstr('\S\+$')
	if prefix->empty()
	    return -2
	endif
	return col('.') - prefix->strlen()
    endif

    var prefix = base
    var citems = []
    for item in vsnip#get_complete_items(bufnr('%'))
	if line->matchstr(Pattern(item.abbr)) == ''
	    continue
	endif
	item.kind = 'S'
	citems->add(item)
    endfor
    citems->sort((v1, v2) => {
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
    var items = citems->copy()->filter((_, v) => v.abbr =~# $'\v^{prefix}')
    if options.fuzzy
	items->extend(citems->copy()->filter((_, v) => v.abbr !~# $'\v^{prefix}'))
    endif
    return items
enddef

import '../autoload/completor.vim'
completor.Register('snippet', Completor, ['*'], 9)
