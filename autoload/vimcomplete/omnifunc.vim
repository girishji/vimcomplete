vim9script

import autoload './util.vim'
import autoload './completor.vim'

export var options: dict<any> = {
    enable: false,
    maxCount: 10,
    dup: true,
    partialWord: ['python3complete#Complete'], # returns 'ow()' instead of 'pow()' when completing builtins.p
}

export def Completor(findstart: number, base: string): any
    if &omnifunc == null_string || completor.IsCompletor('lsp')
        return -2 # cancel but stay in completion mode
    endif
    var Omnifunc = function(&omnifunc)
    var line = getline('.')->strpart(0, col('.') - 1)
    if line =~ '\s$'
        return -2
    endif
    var partial = options.partialWord->index(&omnifunc) != -1
    var prefix = partial ? line->matchstr('\k\+$') : ''
    if findstart == 1
        var startcol = Omnifunc(findstart, base)
        return startcol < 0 ? startcol : startcol + 1 - prefix->len()
    elseif findstart == 2
        return 1
    endif
    var items = Omnifunc(findstart, partial ? base->strpart(prefix->len()) : base)
    if items->empty()
        return []
    endif
    if partial
        var kind = util.GetItemKindValue('Keyword')
        items->map((_, v) => {
            v.word = v.abbr
            v.kind = (v->has_key('kind')) ? v.kind : kind
            return v
        })
    endif
    items = items->slice(0, options.maxCount)
    if options.dup
        items->map((_, v) => v->extend({ dup: 1 }))
    endif
    return items
enddef
