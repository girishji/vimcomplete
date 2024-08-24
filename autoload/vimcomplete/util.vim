vim9script

def WhitespaceOnly(): bool
    return strpart(getline('.'), col('.') - 2, 1) =~ '^\s*$'
enddef

def VCCleverTab(): string
    if exists('*vsnip#jumpable')
        return pumvisible() ? "\<c-n>" : vsnip#jumpable(1) ? "\<Plug>(vsnip-jump-next)" : WhitespaceOnly() ? "\<tab>" : "\<c-n>"
    endif
    return pumvisible() ? "\<c-n>" : WhitespaceOnly() ? "\<tab>" : "\<c-n>"
enddef

def VCCleverSTab(): string
    if exists('*vsnip#jumpable')
        return pumvisible() ? "\<c-p>" : vsnip#jumpable(-1) ? "\<Plug>(vsnip-jump-prev)" : WhitespaceOnly() ? "\<s-tab>" : "\<c-p>"
    endif
    return pumvisible() ? "\<c-p>" : WhitespaceOnly() ? "\<s-tab>" : "\<c-p>"
enddef

export def TabEnable()
    if !get(g:, 'vimcomplete_tab_enable')
        return
    endif
    # suppress error message from iunmap when mapping is missing. maparg() can be used to check.
    :silent! iunmap <buffer> <silent> <tab>
    :silent! iunmap <buffer> <silent> <s-tab>
    :inoremap <buffer> <expr> <tab>   VCCleverTab()
    :snoremap <buffer> <expr> <tab>   VCCleverTab()
    :inoremap <buffer> <expr> <S-Tab> VCCleverSTab()
    :snoremap <buffer> <expr> <S-Tab> VCCleverSTab()
enddef

export def CREnable()
    if !get(g:, 'vimcomplete_cr_enable', 1) || !maparg('<cr>', 'i')->empty()
        return
    endif
    var copts = completor.options
    # By default, Vim's behavior (using `<c-n>` or `<c-x><c-o>`) is as follows:
    # - If an item is selected, pressing `<Enter>` accepts the item and inserts
    #   a newline.
    # - If no item is selected, pressing `<Enter>` dismisses the popup and
    #   inserts a newline.
    # This default behavior occurs when both `noNewlineInCompletion` and
    #   `noNewlineInCompletionEver` are set to `false` (the default settings).
    # - If `noNewlineInCompletion` is `true`, pressing `<Enter>` accepts the
    #   completion choice and inserts a newline if an item is selected. If no
    #   item is selected, it dismisses the popup and does not insert a newline.
    # - If `noNewlineInCompletionEver` is `true`, pressing `<Enter>` will not
    #   insert a newline, even if an item is selected.
    if copts.noNewlineInCompletionEver
        :inoremap <expr> <buffer> <cr> complete_info().selected > -1 ?
                    \ "\<Plug>(vimcomplete-skip)\<c-y>" : "\<Plug>(vimcomplete-skip)\<cr>"
    elseif copts.noNewlineInCompletion
        :inoremap <buffer> <cr> <Plug>(vimcomplete-skip)<cr>
    else
        :inoremap <expr> <buffer> <cr> pumvisible() ? "\<c-y>\<cr>" : "\<cr>"
    endif
enddef

# when completing word where cursor is in the middle, like xxx|yyy, yyy should
# be hidden while tabbing through menu.
var text_action_save = {
    id: -1,
    conceallevel: 0,
    concealcursor: '',
}

export def UndoTextAction(concealed: bool = false): string
    if text_action_save.id > 0
        text_action_save.id->matchdelete()
        text_action_save.id = 0
        if concealed
            &conceallevel = text_action_save.conceallevel
            &concealcursor = text_action_save.concealcursor
        endif
    endif
    return ''
enddef

def TextActionSave(id: number)
    text_action_save.id = id
    text_action_save.conceallevel = &conceallevel
    text_action_save.concealcursor = &concealcursor
enddef

export def TextAction(conceal: bool = false)
    UndoTextAction(conceal)
    if v:completed_item->empty()
        # CompleteDone is triggered very frequently with empty dict
        return
    endif
    # when cursor is in the middle, say xx|yy (| is cursor) pmenu leaves yy at
    # the end after insertion. it looks like xxfooyy. in many cases it is best
    # to remove yy.
    var line = getline('.')
    var curpos = col('.')
    var postfix = line->matchstr('^\k\+', curpos - 1)
    if postfix != null_string
        var newline = line->strpart(0, curpos - 1) .. line->strpart(curpos + postfix->len() - 1)
        setline('.', newline)
    endif
enddef

export def TextActionWrapper(): string
    if pumvisible() && !v:completed_item->empty()
        autocmd CompleteDone <buffer> ++once TextAction()
        feedkeys("\<c-y>")
    endif
    return ''
enddef

export def TextActionPre(conceal: bool = false)
    # hide text that is going to be removed by TextAction()
    var line = getline('.')
    var curpos = col('.')
    var postfix = line->matchstr('^\k\+', curpos - 1)
    if postfix != null_string && v:event.completed_item->has_key('word')
        UndoTextAction(conceal)
        if conceal
            var id = matchaddpos('Conceal', [[line('.'), curpos, postfix->len()]], 100, -1, {conceal: ''})
            if id > 0
                TextActionSave(id)
                :set conceallevel=3
                :set concealcursor=i
            endif
        else
            var id = matchaddpos('VimCompletePostfix', [[line('.'), curpos, postfix->len()]], 100, -1)
            if id > 0
                TextActionSave(id)
            endif
        endif
    endif
enddef

export var info_popup_options = {
    borderchars: ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
    drag: false,
    close: 'none',
}

export def InfoPopupWindow()
    # the only way to change the look of info window is to set popuphidden,
    # subscribe to CompleteChanged, and set the text.
    var id = popup_findinfo()
    if id > 0
        # it is possible to set options only once since info popup window is
        # persistent for a buffer, but it'd require caching a buffer local
        # variable (setbufvar()). not worth it.
        id->popup_setoptions(info_popup_options)
        var item = v:event.completed_item
        if item->has_key('info') && item.info != ''
            # remove null chars (^@) (:h NL-used-for-Nul) by splitting into new lines
            id->popup_settext(item.info->split('[[:cntrl:]]'))
            id->popup_show()
        endif
        # setting completeopt back to 'menuone' causes a flicker, so comment out.
        # setbufvar(bufnr(), '&completeopt', 'menuone,popup,noinsert,noselect')
        # autocmd! VimCompBufAutocmds CompleteChanged <buffer>
    endif
enddef

export var defaultKindItems = [
    [],
    ['Text',           't', "󰉿"],
    ['Method',         'm', "󰆧"],
    ['Function',       'f', "󰊕"],
    ['Constructor',    'C', ""],
    ['Field',          'F', "󰜢"],
    ['Variable',       'v', "󰀫"],
    ['Class',          'c', "󰠱"],
    ['Interface',      'i', ""],
    ['Module',         'M', ""],
    ['Property',       'p', "󰜢"],
    ['Unit',           'u', "󰑭"],
    ['Value',          'V', "󰎠"],
    ['Enum',           'e', ""],
    ['Keyword',        'k', "󰌋"],
    ['Snippet',        'S', ""],
    ['Color',          'C', "󰏘"],
    ['File',           'f', "󰈙"],
    ['Reference',      'r', "󰈇"],
    ['Folder',         'F', "󰉋"],
    ['EnumMember',     'E', ""],
    ['Constant',       'd', "󰏿"],
    ['Struct',         's', "󰙅"],
    ['Event',          'E', ""],
    ['Operator',       'o', "󰆕"],
    ['TypeParameter',  'T', ""],
    ['Buffer',         'B', ""],
    ['Dictionary',     'D', "󰉿"],
    ['Word',           'w', ""],
    ['Option',         'O', "󰘵"],
    ['Abbrev',         'a', ""],
    ['EnvVariable',    'e', ""],
    ['URL',            'U', ""],
    ['Command',        'c', "󰘳"],
    ['Tmux',           'X', ""],
    ['Tag',            'G', "󰌋"],
]

def CreateKindsDict(): dict<list<string>>
    var d = {}
    for it in defaultKindItems
        if !it->empty()
            d[it[0]] = [it[1], it[2]]
        endif
    endfor
    return d
enddef

export var defaultKinds: dict<list<string>> = CreateKindsDict()

import autoload './completor.vim'

# Map LSP (and other) complete item kind to a character/symbol
export def GetItemKindValue(kind: any): string
    var kindValue: string
    if kind->type() == v:t_number  # From LSP
        if kind > 26
            return ''
        endif
        kindValue = defaultKindItems[kind][0]
    else
        kindValue = kind
    endif
    var copts = completor.options
    if copts.customCompletionKinds &&
            copts.completionKinds->has_key(kind)
        kindValue = copts.completionKinds[kind]
    else
        if !defaultKinds->has_key(kindValue)
            echohl ErrorMsg | echo $"vimcomplete: {kindValue} not found in dict" | echohl None
            return ''
        endif
        if copts.kindDisplayType ==? 'symboltext'
            kindValue = $'{defaultKinds[kindValue][0]} {kindValue}'
        elseif copts.kindDisplayType ==? 'icon'
            kindValue = defaultKinds[kindValue][1]
        elseif copts.kindDisplayType ==? 'icontext'
            kindValue = $'{defaultKinds[kindValue][1]} {kindValue}'
        elseif copts.kindDisplayType !=? 'text'
            kindValue = defaultKinds[kindValue][0]
        endif
    endif
    return kindValue
enddef

export def GetKindHighlightGroup(kind: any): string
    var kindValue: string
    if kind->type() == v:t_number  # From LSP
        if kind > 26
            return 'PmenuKind'
        endif
        kindValue = defaultKindItems[kind][0]
    else
        kindValue = kind
    endif
    return 'PmenuKind' .. kindValue
enddef

export def InitKindHighlightGroups()
    for k in defaultKinds->keys()
        var grp = GetKindHighlightGroup(k)
        if hlget(grp)->empty()
            exec $'highlight! default link {grp} PmenuKind'
        endif
    endfor
enddef

# This function is not used at this time. LSP provides a 'kind' number in the 'user_data'.
export def LspCompletionKindsSetDefault()
    if exists('*g:LspOptionsSet')
        var kinds: dict<any> = {}
        for k in defaultKinds->keys()
            kinds[k] = k
        endfor
        g:LspOptionsSet({
            customCompletionKinds: true,
            completionKinds: kinds,
        })
    endif
enddef
