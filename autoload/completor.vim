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
    alwaysOn: true,
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
    for completor in completors
        echom completor
    endfor
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
    # clear prior registrations
    for providers in registered->values()
        providers->filter((_, v) => v.name != name)
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

import autoload './recent.vim'

def DisplayPopup(citems: list<any>, line: string)
    if citems->empty()
        return
    endif
    var startcol = citems[0].startcol # Only one value for startcol is allowed.
    citems->filter((_, v) => v.startcol == startcol)
    citems->sort((v1, v2) => v1.priority > v2.priority ? -1 : 1)

    var items: list<dict<any>> = []
    var prefix = line->slice(startcol - 1)
    var prefixlen = prefix->len()
    if options.shuffleEqualPriority
        for priority in citems->copy()->map((_, v) => v.priority)->uniq()
            var eqitems = citems->copy()->filter((_, v) => v.priority == priority)
            var maxlen = eqitems->copy()->map((_, v) => v.items->len())->max()
            def PopulateItems(exactMatch: bool)
                for idx in maxlen->range()
                    for it in eqitems
                        if !it.items->get(idx)
                            continue
                        endif
                        var repl = it.items[idx]->get('abbr', '')
                        if repl->empty()
                            repl = it.items[idx].word
                        endif
                        if exactMatch
                            if repl->slice(0, prefixlen) ==# prefix
                                items->add(it.items[idx])
                            endif
                        else
                            if repl->slice(0, prefixlen) !=# prefix
                                items->add(it.items[idx])
                            endif
                        endif
                    endfor
                endfor
            enddef
            PopulateItems(true)
            PopulateItems(false)
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
        items = items->copy()->filter((_, v) => v.word->slice(0, prefixlen) ==# prefix) +
            items->copy()->filter((_, v) => v.word->slice(0, prefixlen) !=# prefix)
        # Note: Comparing strings (above) is more robust than regex match
        # since items can include non-keyword characters like ')' that need to
        # be escaped.
    endif

    if options.recency
        items = recent.Recent(items, prefix, options.recentItemCount)
    endif
    items->complete(startcol)
enddef

def GetCurLine(): string
    var m = mode()
    if m != 'i' && m != 'R' && m != 'Rv' # not in insert or replace mode
        return ''
    endif
    var curcol = col('.')
    var curline = getline('.')
    if curcol == 0 || curline->empty()
        return ''
    endif
    return curline->strpart(0, curcol - 1)
enddef

def GetItems(cmp: dict<any>, line: string): list<any>
    # Non ascii chars like ’ occupy >1 columns since they have composing
    # characters. slice(), strpart(), col('.'), len() use byte index, while
    # strcharpart(), strcharlen() use char index.
    var base = line->strpart(cmp.startcol - 1)
    # Note: when triggerCharacter is used in LSP (like '.') base is empty.
    var items = cmp.completor(0, base)
    if options.kindName
        items->map((_, v) => {
            v.kind = $'[{cmp.name}]'
            return v
        })
    endif
    return items
enddef

def AsyncGetItems(curline: string, pendingcompletors: list<any>, partialitems: list<any>, count: number, timer: number)
    var line = GetCurLine()
    # If user already tabbed on an item from popup menu or typed something,
    # then current line will change and this completion prefix is no longer valid
    if curline !=# line
        return
    endif
    # Double check that user has not selected an item in the popup menu
    var compl = complete_info(['selected', 'pum_visible'])
    if compl.pum_visible && compl.selected != -1
        return
    endif
    if count < 0
        DisplayPopup(partialitems, line)
        return
    endif

    var citems = partialitems->copy()
    var asyncompletors: list<any> = []
    for cmp in pendingcompletors
        if cmp.completor(2, '')
            var items = GetItems(cmp, line)
            if !items->empty()
                citems->add({ priority: cmp.priority, startcol: cmp.startcol,
                    items: items })
            endif
        else
            asyncompletors->add(cmp)
        endif
    endfor

    if asyncompletors->empty()
        DisplayPopup(citems, line)
    else
        timer_start(5, function(AsyncGetItems, [line, asyncompletors, citems, count - 1]))
    endif
enddef

var prevCompletionInput: string = ''

def VimComplete()
    var line = GetCurLine()
    if line == prevCompletionInput
        # Text does not change after <c-e> or <c-y> but TextChanged will get
        # called anyway. To avoid <c-e> from closing popup and reopening
        # again check if text is really different.
        return
    endif
    prevCompletionInput = line
    if line->empty()
        return
    endif
    var syncompletors: list<any> = []
    for cmp in completors
        var scol: number = cmp.completor(1, '')
        if scol < 0
            continue
        endif
        syncompletors->add(cmp->extendnew({ startcol: scol }))
    endfor

    # Collect items that are immediately available
    var citems = []
    var asyncompletors: list<any> = []
    for cmp in syncompletors
        if cmp.completor(2, '')
            var items = GetItems(cmp, line)
            if !items->empty()
                citems->add({ priority: cmp.priority, startcol: cmp.startcol,
                    items: items })
            endif
        else
            asyncompletors->add(cmp)
        endif
    endfor

    DisplayPopup(citems, line)
    if !asyncompletors->empty()
        # wait a maximum 2 sec, checking every 2ms to receive items from completors
        timer_start(5, function(AsyncGetItems, [line, asyncompletors, citems, 400]))
    endif
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

def LRU_Cache()
    if !options.recency || v:completed_item->type() != v:t_dict
        return
    endif
    recent.CacheAdd(v:completed_item)
enddef

command VimCompleteCmd pumvisible() ? VimCompletePopupVisible() : VimComplete()

import autoload './util.vim'

export def Enable()
    var bnr = bufnr()
    setbufvar(bnr, '&completeopt', 'menuone,popup,noinsert,noselect')
    setbufvar(bnr, '&completepopup', 'width:80,highlight:Pmenu,align:item')

    # if false, <Enter> in insert mode accepts completion choice and inserts a newline
    # if true, <cr> has default behavior (accept choice or dismiss popup
    # without newline).
    if options.noNewlineInCompletion
        if maparg("<CR>", "i") != ''
            :iunmap <expr> <buffer> <CR>
        endif
    else
        :inoremap <expr> <buffer> <CR> pumvisible() ? "\<C-Y>\<CR>" : "\<CR>"
    endif

    if !options.alwaysOn
        :silent! iunmap <buffer> <c-space>
        :inoremap <c-space> <cmd>VimCompleteCmd<cr>
        :imap <C-@> <C-Space>
    endif

    augroup VimCompBufAutocmds | autocmd! * <buffer>
        if options.alwaysOn
            autocmd TextChangedI <buffer> call VimComplete()
            autocmd TextChangedP <buffer> call VimCompletePopupVisible()
        endif
        autocmd BufEnter,BufReadPost <buffer> call SetupCompletors()
        autocmd CompleteDone <buffer> call LRU_Cache()
    augroup END

    util.TabEnable()
enddef

export def Disable()
    augroup VimCompBufAutocmds | autocmd! * <buffer>
    augroup END
enddef
