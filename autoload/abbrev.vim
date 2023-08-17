vim9script

export var options: dict<any> = {
    enable: false,
    dup: true,
}

def GetAbbrevs(): list<any>
    var lines = execute('ia', 'silent!')
    if lines =~? 'No abbreviation found'
        return []
    endif
    var abb = []
    for line in lines->split("\n")
        var matches = line->matchlist('\v^i\s+\zs(\S+)\s+(.*)$')
        abb->add({ prefix: matches[1], expn: matches[2] })
    endfor
    return abb
enddef

export def Completor(findstart: number, base: string): any
    if findstart == 2
        return 1
    elseif findstart == 1
        var line = getline('.')->strpart(0, col('.') - 1)
        var prefix = line->matchstr('\S\+$')
        if prefix == ''
            return -2
        endif
        return col('.') - prefix->len()
    endif

    var prefix = base
    var abbrevs = GetAbbrevs()
    if abbrevs == []
        return []
    endif
    var citems = []
    for abbrev in abbrevs
        if abbrev.prefix->stridx(prefix) == 0
            citems->add({
                word: abbrev.prefix,
                info: abbrev.expn,
                kind: 'A',
                dup: options.dup ? 1 : 0,
            })
        endif
    endfor
    return citems->empty() ? [] : citems->sort((v1, v2) => {
        return v1.word < v2.word ? -1 : v1.word ==# v2.word ? 0 : 1
    })
enddef
