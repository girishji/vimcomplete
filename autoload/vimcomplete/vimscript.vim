vim9script

import autoload './util.vim'

export var options: dict<any> = {
    enable: false,
    filetypes: ['vim'],
    maxCount: 10,
}

def Prefix(): list<any>
    var type = ''
    var prefix = ''
    var startcol = -1
    var line = getline('.')->strpart(0, col('.') - 1)
    var MatchStr = (pat) => {
        prefix = line->matchstr(pat)
        startcol = col('.') - prefix->len()
        return prefix != ''
    }
    var kind = ''
    var kindhl = ''
    if MatchStr('\v-\>\zs\k+$')
        type = 'function'
        kind = util.GetItemKindValue('Function')
        kindhl = util.GetKindHighlightGroup('Function')
    elseif MatchStr('\v(\A+:|^:)\zs\k+$')
        type = 'command'
        kind = util.GetItemKindValue('Command')
        kindhl = util.GetKindHighlightGroup('Command')
    elseif MatchStr('\v(\A+\&|^\&)\zs\k+$')
        type = 'option'
        kind = util.GetItemKindValue('Option')
        kindhl = util.GetKindHighlightGroup('Option')
    elseif MatchStr('\v(\A+\$|^\$)\zs\k+$')
        type = 'environment'
        kind = util.GetItemKindValue('EnvVariable')
        kindhl = util.GetKindHighlightGroup('EnvVariable')
    elseif MatchStr('\v(\A+\zs\a:|^\a:)\k+$')
        type = 'var'
        kind = util.GetItemKindValue('Variable')
        kindhl = util.GetKindHighlightGroup('Variable')
    else
        # XXX: Following makes vim hang when typing ':cs find g'
        # var matches = line->matchlist('\v<(\a+)!{0,1}\s+(\k+)$')
        # # autocmd, augroup, highlight, map, etc.
        # if matches != [] && matches[1] != '' && matches[2] != ''
        #     type = 'cmdline'
        #     prefix = $'{matches[1]} {matches[2]}'
        #     kind = 'V'
        #     startcol = col('.') - matches[2]->len()
        #     var items = prefix->getcompletion(type)
        #     if items == []
        #         [prefix, type, kind] = ['', '', '']
        #     endif
        # endif
    endif
    if type == ''
        # last resort, search vimscript reserved words dictionary
        if MatchStr('\v\k+$')
            type = 'vimdict'
            kind = util.GetItemKindValue('Keyword')
            kindhl = util.GetItemKindValue('Keyword')
        endif
     endif
    return [prefix, type, kind, kindhl, startcol]
enddef

var dictwords = []

def GetDictCompletion(prefix: string): list<string>
    if dictwords->empty()
        # xxx: Fragile way of getting dictionary file path
        var scripts = getscriptinfo({ name: 'vimscript.vim' })
        var vpath = scripts->filter((_, v) => v.name =~ 'vimcomplete')
        if vpath->empty()
            return []
        endif
        var path = fnamemodify(vpath[0].name, ':p:h:h:h')
        var fname = $'{path}/data/vim9.dict'
        dictwords = fname->readfile()
    endif
    return dictwords->copy()->filter((_, v) => v =~? $'\v^{prefix}')
enddef

export def Completor(findstart: number, base: string): any
    if findstart == 2
        return 1
    endif
    var [prefix, type, kind, kindhl, startcol] = Prefix()
    if findstart == 1
        if type == ''
            return -2
        endif
        return startcol
    endif

    var items = type == 'vimdict' ? GetDictCompletion(base) : prefix->getcompletion(type)
    items->sort((v1, v2) => v1->len() < v2->len() ? -1 : 1)
    items = items->copy()->filter((_, v) => v =~# $'\v^{prefix}') +
        items->copy()->filter((_, v) => v !~# $'\v^{prefix}')
    var citems = []
    for item in items
        citems->add({
            word: item,
            kind: kind,
            kind_hl: kindhl,
        })
    endfor
    return citems->slice(0, options.maxCount) 
enddef
