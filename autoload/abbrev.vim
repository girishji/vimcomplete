vim9script

import autoload 'util.vim'

export var options: dict<any> = {
    enable: false,
    dup: true,
}

def GetAbbrevs(prefix: string): list<any>
    var lines = execute('ia', 'silent!')
    if lines =~? gettext('No abbreviation found')
        return []
    endif
    var abb = []
    for line in lines->split("\n")
        var matches = line->matchlist('\v^i\s+\zs(\S+)\s+(.*)$')
        if matches[1]->stridx(prefix) == 0
            abb->add({ prefix: matches[1], expn: matches[2] })
        endif
    endfor
    return abb
enddef

export def Completor(findstart: number, base: string): any
    if findstart == 2
        return 1
    elseif findstart == 1
        var line = getline('.')->strpart(0, col('.') - 1)
        var prefix = line->matchstr('\S\+$')
        if prefix->empty()
            return -2
        endif
        if GetAbbrevs(prefix)->empty()
            prefix = line->matchstr('\k\+$')
            if prefix->empty()
                return -2
            endif
        endif
        return col('.') - prefix->len()
    endif

    var prefix = base
    var abbrevs = GetAbbrevs(prefix)
    if abbrevs == []
        return []
    endif
    var citems = []
    var kind = util.GetItemKindValue('Abbrev')
    for abbrev in abbrevs
        citems->add({
            word: abbrev.prefix,
            info: abbrev.expn,
            kind: kind,
            dup: options.dup ? 1 : 0,
        })
    endfor
    return citems->empty() ? [] : citems->sort((v1, v2) => {
        return v1.word < v2.word ? -1 : v1.word ==# v2.word ? 0 : 1
    })
enddef
