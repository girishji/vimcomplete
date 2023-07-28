vim9script

# Autocomplete file path

export var options: dict<any> = {}

export def Completor(findstart: number, base: string): any
    if findstart == 2
	return 1
    elseif findstart == 1
	var line = getline('.')->strpart(0, col('.') - 1)
	var prefix = line->matchstr('\f\+$')
	if prefix == '' || prefix =~ '?$' || prefix !~ (has('unix') ? '/' : '\')
	    return -2
	endif
	return col('.') - prefix->strlen()
    endif

    var prefix = base
    var citems = []
    for path in getcompletion(prefix, 'file', 1)
	citems->add({
	    word: path,
	    kind: 'P',
	})
    endfor
    return citems
enddef
