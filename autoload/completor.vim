vim9script

export var options: dict<any> = {
    noNewlineInCompletion: false,
    matchCase: true,
    sortLength: false,
    kindName: true,
    buffer: { enabled: true, match: 'icase', max: 10, priority: 10 },
    lsp: { enabled: false, max: 20, priority: 8 },
    path: { enabled: false, max: 20, priority: 11 }, # higher priority than buffer, so /xx/yy work
    abbrev: { enabled: true, max: 1000, priority: 9 },
    dictionary: { enabled: false, max: 5, priority: 2 },
    vssnip: { enabled: false, max: 1000, priority: 9 },
    vimscript: { enabled: true, max: 1000, priority: 9 },
}

var registered: dict<any> = { any: [] }

export def Register(name: string, Completor: func, ftype: list<string>, priority: number)
    var p = priority
    if options->has_key(name) && options[$'{name}']->has_key('priority')
	p = options[$'{name}'].priority
    endif
    if ftype == []
	return
    elseif ftype[0] == '*'
	registered.any->add({name: name, completor: Completor, priority: p})
    else
	for ft in ftype
	    if !registered->has_key(ft)
		registered[$'{ft}'] = []
	    endif
	    registered[$'{ft}']->add({name: name, completor: Completor, priority: p})
	endfor
    endif
enddef

var completors: list<any>

def SetupCompletors()
    if &filetype == '' || !registered->has_key(&filetype)
	echom 'setting completors 1'
	completors = registered.any
    else
	completors = registered[&ft] + registered.any
    endif
    completors->sort((v1, v2) => v2.priority - v1.priority)
    echom completors
enddef

export def ShowCompletors()
    echom completors
enddef

def IComplete()
    var curcol = charcol('.')
    var curline = getline('.')
    if curcol == 0 || curline->empty() ||
	   (curline->len() >= curcol && curline[curcol - 1] =~ '\k')
	return
    endif

    var line = curline->strpart(0, curcol - 1)
    var context = line->matchstr('\k\+$')
    var kwstartcol: number = curcol - context->strlen()
    var startcol: number = -1

    var nextcompletors: list<any> = []
    for cmp in completors
	var scol: number = cmp.completor(1, '')
	if scol == -3 || scol == -2
	    continue
	endif
	if scol != kwstartcol
	    if scol > startcol
		nextcompletors = []
		startcol = scol
		context = line->slice(scol - 1)
	    endif
	    nextcompletors->add(cmp)
	elseif startcol == -1
	    nextcompletors->add(cmp)
	endif
    endfor
    startcol = startcol == -1 ? kwstartcol : startcol

    var base = line->slice(startcol - 1)
    var citems = []
    var asyncompletors: list<any> = []
    def GetItems(cmp: dict<any>): list<any>
	var items = cmp.completor(0, base)
	if options.kindName
	    items->map((_, v) => {
		v.kind = $'[{cmp.name}]'
		v.dup = 1
		return v
	    })
	endif
	return items
    enddef
    for cmp in nextcompletors
	if cmp.completor(2, '')
	    citems->add({ priority: cmp.priority, items: GetItems(cmp) })
	else
	    asyncompletors->add(cmp)
	endif
    endfor
    for cmp in asyncompletors
	var count: number = 0
	while !cmp.completor(2, '') && count < 1000
	    sleep 2m
	    count += 1
	endwhile
	citems->add({ priority: cmp.priority, items: GetItems(cmp) })
    endfor
    if context !=# line->slice(startcol - 1)
	# Async wait could have allowed new keystrokes (lsp waits on complete_check())
	return
    endif
    citems->sort((v1, v2) => v1.priority < v2.priority ? -1 : 1)

    var items: list<dict<any>> = []
    for it in citems
	items->extend(it.items)
    endfor
    if items->empty()
	return
    endif
    var m = mode()
    if m != 'i' && m != 'R' && m != 'Rv' # not in insert or replace mode
	return
    endif
    if options.sortLength
	items->sort((v1, v2) => v1.word->len() <= v2.word->len() ? -1 : 1)
    endif
    if options.matchCase
	items = items->copy()->filter((_, v) => v.word =~# $'\v^{context}') +
	    items->copy()->filter((_, v) => v.word !~# $'\v^{context}')
    endif
    items->complete(startcol)
enddef

def ICompletePopupVisible()
    var compl = complete_info(['selected', 'pum_visible'])
    if !compl.pum_visible  # should not happen
	return
    endif
    if compl.selected == -1 # no items is selected in the menu
	IComplete()
    endif
enddef

export def Enable()
    var bnr = bufnr()
    setbufvar(bnr, '&completeopt', 'menuone,popup,noinsert,noselect')
    setbufvar(bnr, '&completepopup', 'width:80,highlight:Pmenu,align:item')

    # <Enter> in insert mode stops completion and inserts a <Enter>
    if !options.noNewlineInCompletion
      :inoremap <expr> <buffer> <CR> pumvisible() ? "\<C-Y>\<CR>" : "\<CR>"
    endif

    augroup ICompBufAutocmds | autocmd! * <buffer>
	autocmd TextChangedI <buffer> call IComplete()
	autocmd TextChangedP <buffer> call ICompletePopupVisible()
	autocmd BufEnter,BufReadPost <buffer> call SetupCompletors()
    augroup END
enddef

export def Disable()
    augroup ICompBufAutocmds | autocmd! * <buffer>
    augroup END
enddef
