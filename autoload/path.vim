vim9script

# Autocomplete file path

export var options: dict<any> = {
    bufferRelativePath: true,
}

export def Completor(findstart: number, base: string): any
    if findstart == 2
	return 1
    elseif findstart == 1
	var line = getline('.')->strpart(0, col('.') - 1)
	var prefix = line->matchstr('\f\+$')
	if !prefix->empty() &&
		!(line->matchstr('\c\vhttp(s)?(:)?(/){0,2}\S+$')->empty())
	    return -2
	endif
	if prefix->empty() || prefix =~ '?$' || prefix !~ (has('unix') ? '/' : '\')
	    return -2
	endif
	return col('.') - prefix->strlen()
    endif

    var citems = []
    var cwd: string = ''
    try
	if options.bufferRelativePath && expand('%:h') !=# '.' # not already in buffer dir
	    # change directory to get completions for paths relative to current buffer dir
	    cwd = getcwd()
	    :exec 'cd ' .. expand('%:p:h')
	endif
	for item in getcompletion(base, 'file', 1)
	    citems->add({
		word: item,
		kind: 'P',
		menu: (isdirectory(item) ? "[dir]" : "[file]")
	    })
	endfor
    catch # on MacOS it does not complete /tmp/* (throws E344, looks for /private/tmp/...)
	echom v:exception
    finally
	if !cwd->empty()
	    :exec $'cd {cwd}'
	endif
    endtry
    return citems
enddef
