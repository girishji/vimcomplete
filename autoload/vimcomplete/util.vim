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

var defaultKinds: dict<list<string>> = {
    'Text':           ['t', "󰉿"],
    'Method':         ['m', "󰆧"],
    'Function':       ['f', "󰊕"],
    'Constructor':    ['C', ""],
    'Field':          ['F', "󰜢"],
    'Variable':       ['v', "󰀫"],
    'Class':          ['c', "󰠱"],
    'Interface':      ['i', ""],
    'Module':         ['M', ""],
    'Property':       ['p', "󰜢"],
    'Unit':           ['u', "󰑭"],
    'Value':          ['V', "󰎠"],
    'Enum':           ['e', ""],
    'Keyword':        ['k', "󰌋"],
    'Snippet':        ['S', ""],
    'Color':          ['C', "󰏘"],
    'File':           ['f', "󰈙"],
    'Reference':      ['r', "󰈇"],
    'Folder':         ['F', "󰉋"],
    'EnumMember':     ['E', ""],
    'Constant':       ['d', "󰏿"],
    'Struct':         ['s', "󰙅"],
    'Event':          ['E', ""],
    'Operator':       ['o', "󰆕"],
    'TypeParameter':  ['T', ""],
    'Buffer':         ['B', ""],
    'Word':           ['w', ""],
    'Option':         ['O', "󰘵"],
    'Abbrev':         ['a', ""],
    'EnvVariable':    ['e', ""],
    'URL':            ['U', ""],
    'Command':        ['c', "󰘳"],
}

import autoload './completor.vim'

# Map LSP complete item kind to a character
export def GetItemKindValue(kind: string): string
    var kindValue: string = kind
    var copts = completor.options
    if copts.customCompletionKinds &&
            copts.completionKinds->has_key(kind)
        kindValue = copts.completionKinds[kind]
    else
        if !defaultKinds->has_key(kind)
            echohl ErrorMsg | echo $"vimcomplete: {kind} not found in dict" | echohl None
        endif
        if copts.kindDisplayType == 'symbol'
            kindValue = defaultKinds[kind][0]
        elseif copts.kindDisplayType == 'symboltext'
            kindValue = $'{defaultKinds[kind][0]} {kind}'
        elseif copts.kindDisplayType == 'icon'
            kindValue = defaultKinds[kind][1]
        elseif copts.kindDisplayType == 'icontext'
            kindValue = $'{defaultKinds[kind][1]} {kind}'
        elseif copts.kindDisplayType == 'text'
            kindValue = kind
        else
            kindValue = defaultKinds[kind][0]
        endif
    endif
    return kindValue
enddef

export def LspCompletionKindsSetDefault()
    var copts = completor.options
    if (copts.customCompletionKinds || copts.kindDisplayType != 'symbol') &&
            exists('*g:LspOptionsSet')
        var kinds: dict<any> = {}
        for k in defaultKinds->keys()
            kinds[k] = GetItemKindValue(k)
        endfor
        g:LspOptionsSet({
            customCompletionKinds: true,
            completionKinds: kinds,
        })
    endif
enddef
