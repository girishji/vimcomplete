vim9script

# Main autocompletion engine

export var options: dict<any> = {
    noNewlineInCompletion: false,
    matchCase: true,
    sortByLength: false,
    kindName: true,
    recency: true,
    recentItemCount: 5,
    shuffleEqualPriority: false,
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
    def AddCompletor(ft: string)
	if !registered->has_key(ft)
	    registered[ft] = []
	endif
	if registered[ft]->indexof((_, v) => v.name == name) == -1
	    registered[ft]->add({name: name, completor: Completor, priority: priority})
	endif
    enddef
    if ftype->empty()
	return
    endif
    for completors in values(registered)
	var idx = completors->indexof((_, v) => v.name == name)
	if idx != -1
	    completors->remove(idx)
	endif
    endfor
    if ftype[0] == '*'
	AddCompletor('any')
    else
	for ft in ftype
	    AddCompletor(ft)
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
    var m = mode()
    if m != 'i' && m != 'R' && m != 'Rv' # not in insert or replace mode
	return
    endif
    var curcol = charcol('.')
    var curline = getline('.')
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
    var startcol = citems[0].startcol # only one value for startcol valid
    citems->filter((_, v) => v.startcol == startcol) 
    citems->sort((v1, v2) => v1.priority > v2.priority ? -1 : 1)

    var items: list<dict<any>> = []
    if options.shuffleEqualPriority
	for priority in citems->copy()->map((_, v) => v.priority)->uniq()
	    var eqitems = citems->copy()->filter((_, v) => v.priority == priority)
	    var maxlen = eqitems->copy()->map((_, v) => v.items->len())->max()
	    for idx in maxlen->range()
		for it in eqitems
		    if !it.items->get(idx)
			continue
		    endif
		    items->add(it.items[idx])
		endfor
	    endfor
	endfor
    else
	for it in citems
	    items->extend(it.items)
	endfor
    endif

    if options.sortByLength
	items->sort((v1, v2) => v1.word->len() <= v2.word->len() ? -1 : 1)
    endif

    if options.matchCase
	var base = line->slice(startcol - 1)
	var baselen = base->len()
	items = items->copy()->filter((_, v) => v.word->slice(0, baselen) ==# base) +
	    items->copy()->filter((_, v) => v.word->slice(0, baselen) !=# base)
	# Note: Comparing strings (above) is more robust than regex match
	# since items can include non-word characters like ')' that need to
	# be escaped.
    endif

    if options.recency
	items = frequent.Frequent(items, options.recentItemCount)
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
    if !options.recency || v:completed_item->type() != v:t_dict
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
