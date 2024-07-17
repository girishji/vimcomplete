vim9script

# Main autocompletion engine

import autoload './util.vim'
import autoload './lsp.vim'

export var options: dict<any> = {
    noNewlineInCompletion: false,
    noNewlineInCompletionEver: false,
    matchCase: true,
    sortByLength: false,
    recency: true,
    recentItemCount: 5,
    shuffleEqualPriority: false,
    alwaysOn: true,
    showSource: true,
    showKind: true,
    customCompletionKinds: false,
    completionKinds: {},
    kindDisplayType: 'symboltext', # 'icon', 'icontext', 'text', 'symboltext', 'symbol', 'text'
    customInfoWindow: true,
    postfixClobber: false,  # remove yyy in xxx<cursor>yyy
    postfixHighlight: false, # highlight yyy in xxx<cursor>yyy
    triggerWordLen: 0,
    debug: false,
}

var saved_options: dict<any> = {}

export def GetOptions(provider: string): dict<any>
    return saved_options->get(provider, {})
enddef

export def SetOptions(opts: dict<any>)
    saved_options = opts
enddef

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

export def IsCompletor(source: string): bool
    return  completors->indexof((_, v) => v.name == source) != -1
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
    var prefix = line->strpart(startcol - 1)
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
                            if repl->strpart(0, prefixlen) ==# prefix
                                items->add(it.items[idx])
                            endif
                        else
                            if repl->strpart(0, prefixlen) !=# prefix
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
        items = items->copy()->filter((_, v) => v.word->strpart(0, prefixlen) ==# prefix) +
            items->copy()->filter((_, v) => v.word->strpart(0, prefixlen) !=# prefix)
        # Note: Comparing strings (above) is more robust than regex match, since
        # items can include non-keyword characters like ')' which otherwise
        # needs escaping.
    endif

    if options.recency
        items = recent.Recent(items, prefix, options.recentItemCount)
    endif
    if options.debug
        echom items
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
    # characters. strpart(), col('.'), len() use byte index, while
    # strcharpart(), slice(), strcharlen() use char index.
    var base = line->strpart(cmp.startcol - 1)
    # Note: when triggerCharacter is used in LSP (like '.') base is empty.
    var items = cmp.completor(0, base)
    if options.showSource
        items->map((_, v) => {
            if v->has_key('menu')
                if v.menu !~? $'^\[{cmp.name}]'
                    v.menu = $'[{cmp.name}] {v.menu}'
                endif
            else
                v.menu = $'[{cmp.name}]'
            endif
            return v
        })
    endif
    if !options.showKind
        items->map((_, v) => {
            if v->has_key('kind')
                v->remove('kind')
            endif
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
    var partial_items_returned = false
    for cmp in pendingcompletors
        if cmp.completor(2, '') > 0
            var items = GetItems(cmp, line)
            if !items->empty()
                citems->add({ priority: cmp.priority, startcol: cmp.startcol,
                    items: items })
            endif
            if cmp.completor(2, '') == 2  # more items expected
                asyncompletors->add(cmp)
                partial_items_returned = true
            endif
        else
            asyncompletors->add(cmp)
        endif
    endfor

    if asyncompletors->empty() || partial_items_returned
        DisplayPopup(citems, line)
    else
        timer_start(5, function(AsyncGetItems, [line, asyncompletors, citems, count - 1]))
    endif
enddef

# Text does not change after <c-e> or <c-y> but TextChanged will get
# called anyway. To avoid <c-e> and <c-y> from closing popup and reopening
# again, set a flag.
# https://github.com/girishji/vimcomplete/issues/37
var skip_complete: bool = false

export def SkipCompleteSet(): string
    if pumvisible()
        skip_complete = true
    endif
    return ''
enddef

def SkipComplete(): bool
    if skip_complete
        skip_complete = false
        return true
    endif
    # if exists('*vsnip#jumpable') && (vsnip#jumpable(1) || vsnip#jumpable(-1))
    if exists('*vsnip#jumpable') && vsnip#jumpable(1)
        return true
    endif
    return false
enddef

def VimComplete()
    if SkipComplete()
        return
    endif
    var line = GetCurLine()
    if line->empty()
        return
    endif
    if options.triggerWordLen > 0
        var keyword = line->matchstr('\k\+$')
        if keyword->len() < options.triggerWordLen && lsp.GetTriggerKind() != 2
            return
        endif
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

export def DoComplete(): string
    pumvisible() ? VimCompletePopupVisible() : VimComplete()
    return ''
enddef

def LRU_Cache()
    if v:completed_item->empty()
        # CompleteDone is triggered very frequently with empty dict
        return
    endif
    if options.recency
        recent.CacheAdd(v:completed_item)
    endif
enddef

export def Enable()
    var bnr = bufnr()
    if options.customInfoWindow
        setbufvar(bnr, '&completeopt', $'menuone,popuphidden,noselect,noinsert')
    else
        setbufvar(bnr, '&completeopt', $'menuone,popup,noselect,noinsert')
    endif
    setbufvar(bnr, '&completepopup', 'width:80,highlight:Pmenu,align:item')

    if maparg('<cr>', 'i')->empty()
        # if noNewlineInCompletion is false, <Enter> in insert mode accepts
        # completion choice and inserts a newline
        # if true, <cr> has default behavior (accept choice and insert newline,
        # or dismiss popup without inserting newline).
        # if noNewlineInCompletionEver is 'true' newline will not be inserted even if item is selected.
        if options.noNewlineInCompletionEver
            :inoremap <expr> <buffer> <cr> complete_info().selected > -1 ?
                        \ "\<Plug>(vimcomplete-skip)\<c-y>" : "\<Plug>(vimcomplete-skip)\<cr>"
        elseif options.noNewlineInCompletion
            :inoremap <buffer> <cr> <Plug>(vimcomplete-skip)<cr>
        else
            :inoremap <expr> <buffer> <cr> pumvisible() ? "\<c-y>\<cr>" : "\<cr>"
        endif
    endif

    if options.alwaysOn
        :inoremap <buffer> <c-y> <Plug>(vimcomplete-skip)<c-y>
        :inoremap <buffer> <c-e> <Plug>(vimcomplete-skip)<c-e>
    else
        :silent! iunmap <buffer> <c-space>
        :inoremap <buffer> <c-space> <Plug>(vimcomplete-do-complete)
        :imap <buffer> <C-@> <C-Space>
    endif

    if options.postfixClobber
        :inoremap <silent><expr> <Plug>(vimcomplete-undo-text-action) util.UndoTextAction(true)
        :inoremap <buffer> <c-c> <Plug>(vimcomplete-undo-text-action)<c-c>
    elseif options.postfixHighlight
        :inoremap <silent><expr> <Plug>(vimcomplete-undo-text-action) util.UndoTextAction()
        :inoremap <buffer> <c-c> <Plug>(vimcomplete-undo-text-action)<c-c>
        :highlight default link VimCompletePostfix DiffChange
        :inoremap <expr> <c-l> util.TextActionWrapper()
    endif

    augroup VimCompBufAutocmds | autocmd! * <buffer>
        if options.alwaysOn
            autocmd TextChangedI <buffer> VimComplete()
            autocmd TextChangedP <buffer> VimCompletePopupVisible()
        endif
        autocmd BufEnter,BufReadPost,FileType <buffer> SetupCompletors()  # FileType, for 'ft' set in 'modeline'
        autocmd CompleteDone <buffer> LRU_Cache()
        if options.postfixClobber
            autocmd CompleteDone <buffer> util.TextAction(true)
            autocmd CompleteChanged <buffer> util.TextActionPre(true)
            autocmd InsertLeave <buffer> util.UndoTextAction(true)
        elseif options.postfixHighlight
            autocmd CompleteChanged <buffer> util.TextActionPre()
            autocmd CompleteDone,InsertLeave <buffer> util.UndoTextAction()
        endif
        if options.customInfoWindow
            autocmd CompleteChanged <buffer> util.InfoPopupWindow()
        endif
    augroup END

    util.TabEnable()
enddef

export def Disable()
    augroup VimCompBufAutocmds | autocmd! * <buffer>
    augroup END
enddef
