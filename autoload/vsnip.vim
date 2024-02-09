vim9script

# Interface to github.com/hrsh7th/vim-vsnip

import autoload 'util.vim'

export var options: dict<any> = {
    enable: false,
    maxCount: 10,
    adaptNonKeyword: false,
    dup: true,
}

def Pattern(abbr: string): string
    var chars = escape(abbr, '\/?')->split('\zs')
    var chars_pattern = '\%(\V' .. chars->join('\m\|\V') .. '\m\)'
    var separator = chars[0] =~ '\a' ? '\<' : ''
    return $'{separator}\V{chars[0]}\m{chars_pattern}*$'
enddef

def GetCandidates(line: string): list<dict<any>>
    var citems = []
    for item in vsnip#get_complete_items(bufnr('%'))
        if line->matchstr(Pattern(item.abbr)) == ''
            continue
        endif
        item.kind = util.GetItemKindValue('Snippet')
        citems->add(item)
    endfor
    return citems
enddef

def GetItems(): dict<any>
    var line = getline('.')->strpart(0, col('.') - 1)
    var items = GetCandidates(line)
    var prefix = line->matchstr('\S\+$')
    if prefix->empty() || items->empty()
        return { startcol: -2, items: [] }
    endif
    var prefixlen = prefix->len()
    var filtered = items->copy()->filter((_, v) => v.abbr->slice(0, prefixlen) ==? prefix)
    var startcol = col('.') - prefixlen
    var kwprefix = line->matchstr('\k\+$')
    var lendiff = prefixlen - kwprefix->len()
    if !filtered->empty()
        if options.adaptNonKeyword && !kwprefix->empty() && lendiff > 0
            # When completing '#if', LSP supplies appropriate completions
            # items but without '#'. To mix vsnip and LSP items '#' needs to
            # be removed from snippet (in 'user_data') and 'word'
            for item in filtered
                item.word = item.word->slice(lendiff)
                var user_data = item.user_data->json_decode()
                var snippet = user_data.vsnip.snippet
                if !snippet->empty()
                    snippet[0] = snippet[0]->slice(lendiff)
                endif
                item.user_data = user_data->json_encode()
            endfor
            startcol += lendiff
        endif
    endif
    return { startcol: startcol, items: filtered }
enddef

export def Completor(findstart: number, base: string): any
    if findstart == 2
        return 1
    endif
    if !exists('*vsnip#get_complete_items')
        return -2
    endif
    var citems = GetItems()
    if findstart == 1
        return citems.items->empty() ? -2 : citems.startcol
    endif

    citems.items->sort((v1, v2) => {
        var w1 = v1.abbr
        var w2 = v2.abbr
        if w1->len() < w2->len()
            return -1
        elseif w1->len() == w2->len()
            return w1 < w2 ? 1 : -1
        else
            return 1
        endif
    })
    if options.dup
        citems.items->map((_, v) => v->extend({ dup: 1 }))
    endif
    return citems.items->slice(0, options.maxCount) 
enddef
