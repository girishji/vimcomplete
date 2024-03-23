vim9script

export var options: dict<any> = {}

var cache: dict<any> = {}  # LRU cache

const CacheSize = 10000

def LRU_Keys(): list<string>
    var leastrecent = cache->items()->copy() # [key, value] list
    leastrecent->sort((v1, v2) => v1[1].reltime < v2[1].reltime ? -1 : 1)
    return leastrecent->slice(0, max([ 1, CacheSize / 100 ]))
enddef

def KeyWord(item: dict<any>): string
    return item->has_key('abbr') && !item.abbr->empty() ? item.abbr : item.word
enddef

def Key(item: dict<any>): string
    if !item->has_key('kind')
        return ''
    endif
    return $'{item.kind}{KeyWord(item)}'
enddef

export def CacheAdd(item: dict<any>)
    if cache->len() > CacheSize
        for it in LRU_Keys()
            cache->remove(it[0])
        endfor
    endif
    var key = Key(item)
    if !key->empty()
        cache[key] = { item: item, reltime: reltime()->reltimefloat() }
    endif
enddef

export def Recent(items: list<dict<any>>, prefix: string, maxcount: number = 10): list<dict<any>>
    var candidates = []
    for item in items
        var key = Key(item)
        if !key
            continue
        endif
        if cache->has_key(key) && KeyWord(item)->strpart(0, prefix->len()) ==# prefix
            candidates->add({ key: key, item: item, reltime: cache[key].reltime })
        endif
    endfor
    if candidates->empty()
        return items
    endif
    candidates->sort((v1, v2) => v1.reltime < v2.reltime ? 1 : -1)
    candidates = candidates->slice(0, maxcount + 1)

    var citems: list<dict<any>> = []
    var iscandidate = {}
    for item in candidates
        citems->add(item.item)
        iscandidate[item.key] = 1
    endfor
    for item in items
        var key = Key(item)
        if !key->empty()  && iscandidate->has_key(key)
            continue
        endif
        citems->add(item)
    endfor
    return citems
enddef
