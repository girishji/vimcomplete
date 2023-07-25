vim9script

export var options: dict<any> = {
    noNewlineInCompletion: false,
    matchCase: true,
    sortLength: false,
    kindName: true,
    frequecySort: true,
    frequecyItemCount: 5,
}

export var alloptions: dict<any> = {}

var registered: dict<any> = { any: [] }
var completors: list<any>

export def SetupCompletors()
    if &filetype == '' || !registered->has_key(&filetype)
	completors = registered.any
    else
	completors = registered[&ft] + registered.any
    endif
    completors->sort((v1, v2) => v2.priority - v1.priority)
enddef

export def ShowCompletors()
    echom completors
enddef

export def ClearRegistered()
    registered = { any: [] }
enddef

export def Register(name: string, Completor: func, ftype: list<string>, priority: number)
    if ftype == []
	return
    elseif ftype[0] == '*'
	registered.any->add({name: name, completor: Completor, priority: priority})
    else
	for ft in ftype
	    if !registered->has_key(ft)
		registered[$'{ft}'] = []
	    endif
	    registered[$'{ft}']->add({name: name, completor: Completor, priority: priority})
	endfor
    endif
    SetupCompletors()
enddef

export def Unregister(name: string)
    for providers in registered->values()
	providers->filter((_, v) => v.name != name) 
    endfor
    SetupCompletors()
enddef

import autoload './frequent.vim'

def VimComplete()
    var curcol = charcol('.')
    var curline = getline('.')
    # if curcol == 0 || curline->empty() ||
	   # (curline->len() >= curcol && curline[curcol - 1] =~ '\k')
    if curcol == 0 || curline->empty()
	return
    endif

    var line = curline->strpart(0, curcol - 1)
    var syncompletors: list<any> = []
    for cmp in completors
	var scol: number = cmp.completor(1, '')
	if scol == -3 || scol == -2
	    continue
	endif
	syncompletors->add(cmp->extendnew({ startcol: scol }))
    endfor

    def GetItems(cmp: dict<any>): list<any>
	var base = line->slice(cmp.startcol - 1)
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

    var citems = []
    var asyncompletors: list<any> = []
    for cmp in syncompletors
	if cmp.completor(2, '')
	    var items = GetItems(cmp)
	    if !items->empty()
		citems->add({ priority: cmp.priority, startcol: cmp.startcol,
		    items: items })
	    endif
	else
	    asyncompletors->add(cmp)
	endif
    endfor

    for cmp in asyncompletors
	var count: number = 0
	while !cmp.completor(2, '') && count < 1000
	    if complete_check()
		return
	    endif
	    sleep 2m
	    count += 1
	endwhile
	var items = GetItems(cmp)
	if !items->empty()
	    citems->add({ priority: cmp.priority, startcol: cmp.startcol,
		items: items })
	endif
    endfor
    if citems->empty()
	return
    endif
    var startcol = citems[0].startcol
    citems->filter((_, v) => v.startcol == startcol) 
    citems->sort((v1, v2) => v1.priority > v2.priority ? -1 : 1)

    var items: list<dict<any>> = []
    for it in citems
	items->extend(it.items)
    endfor
    var m = mode()
    if m != 'i' && m != 'R' && m != 'Rv' # not in insert or replace mode
	return
    endif
    if options.sortLength
	items->sort((v1, v2) => v1.word->len() <= v2.word->len() ? -1 : 1)
    endif
    if options.matchCase
	# if context includes non-keyword chars like `(` then =~ gives error
	#   filter only when context has keyword chars
	var context = line->matchstr('\k\+$')
	if startcol == line->len() - context->len() + 1
	    items = items->copy()->filter((_, v) => v.word =~# $'\v^{context}') +
		items->copy()->filter((_, v) => v.word !~# $'\v^{context}')
	endif
    endif
    if options.frequecySort
	items = frequent.Frequent(items, options.frequecyItemCount)
    endif
    items->complete(startcol)
enddef

def VimCompletePopupVisible()
    var compl = complete_info(['selected', 'pum_visible'])
    if !compl.pum_visible  # should not happen
	return
    endif
    if compl.selected == -1 # no items is selected in the menu
	VimComplete()
    endif
enddef

import autoload './util.vim'

def LRU_Cache()
    if !options.frequecySort || v:completed_item->type() != v:t_dict
	return
    endif
    frequent.CacheAdd(v:completed_item)
enddef

export def Enable()
    var bnr = bufnr()
    setbufvar(bnr, '&completeopt', 'menuone,popup,noinsert,noselect')
    setbufvar(bnr, '&completepopup', 'width:80,highlight:Pmenu,align:item')

    # <Enter> in insert mode stops completion and inserts a <Enter>
    if !options.noNewlineInCompletion
      :inoremap <expr> <buffer> <CR> pumvisible() ? "\<C-Y>\<CR>" : "\<CR>"
    endif

    augroup VimCompBufAutocmds | autocmd! * <buffer>
	autocmd TextChangedI <buffer> call VimComplete()
	autocmd TextChangedP <buffer> call VimCompletePopupVisible()
	autocmd BufEnter,BufReadPost <buffer> call SetupCompletors()
	autocmd CompleteDone <buffer> call LRU_Cache()
    augroup END

    util.TabEnable()
enddef

export def Disable()
    augroup VimCompBufAutocmds | autocmd! * <buffer>
    augroup END
enddef
