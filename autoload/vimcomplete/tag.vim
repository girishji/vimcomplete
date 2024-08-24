vim9script

import autoload './util.vim'

export var options: dict<any> = {
    enable: false,
    maxCount: 10,
}

export def Completor(findstart: number, base: string): any
    if findstart == 2
        return 1
    elseif findstart == 1
        var line = getline('.')->strpart(0, col('.') - 1)
        var prefix = line->matchstr('\k\+$')
        if prefix->empty()
            return -2
        endif
        return col('.') - prefix->len()
    endif

    var prefix = base
    var taglist = taglist($'^{base}', '%:h'->expand())
    if taglist == []
        return []
    endif
    var citems = []
    var found = {}
    for tag in taglist
        if !found->has_key(tag.name)
            found[tag.name] = true
            citems->add({
                word: tag.name,
                menu: tag.kind,
                info: tag.filename,
                kind: util.GetItemKindValue('Tag'),
                kind_hlgroup: util.GetKindHighlightGroup('Tag'),
                dup: 0,
            })
        endif
    endfor
    return citems->slice(0, options.maxCount)
enddef
