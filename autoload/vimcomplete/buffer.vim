vim9script

import autoload './util.vim'

# Completion from current and loaded buffers

# Completion candidates are sorted according to locality (how close they are to
# cursor). Case sensitive matches are preferred to case insensitive and partial
# matches. If user type 'fo', then 'foo' appears before 'Foo' and 'barfoo'.

export var options: dict<any> = {
    timeout: 100,
    maxCount: 10,
    otherBuffersCount: 3,       # Max count of other listed buffers to search
    completionMatcher: 'icase', # 'case', 'fuzzy', 'icase'
    urlComplete: false,
    envComplete: false,
    dup: true,
}

# Return a list of keywords from a buffer
def BufWords(bufnr: number, prefix: string, curbuf: bool = false): list<any>
    var found = {}
    var start = reltime()
    var timeout = options.timeout
    var linenr = 1
    var items = []
    var kind = util.GetItemKindValue('Keyword')
    var bufname = ''
    def GetLines(): list<any>
        if curbuf
            return getline(1, '$')
        else
            bufname = $'#{bufnr}'->expand()->fnamemodify(':t')
            return getbufline(bufnr, 1, '$')
        endif
    enddef
    for line in GetLines()
        for word in line->split('\W\+')
            if !found->has_key(word) && word->len() > 1
                found[word] = 1
                if curbuf
                    items->add({word: word, kind: kind})
                else
                    items->add({word: word, kind: kind, menu: bufname})
                endif
            endif
        endfor
        # Check every 200 lines if timeout is exceeded
        if (timeout > 0 && linenr % 200 == 0 &&
                start->reltime()->reltimefloat() * 1000 > timeout)
            break
        endif
        linenr += 1
    endfor
    if options.completionMatcher == 'fuzzy'
        return items->matchfuzzy(prefix, {limit: 100, key: 'word'})
    else
        var pattern = (options.completionMatcher == 'icase') ? $'\c^{prefix}' : $'\C^{prefix}'
        var citems = []
        for item in items
            try
                if item.word =~ pattern
                    citems->add(item)
                endif
            catch # E33 is caught if prefix has a "~"
            endtry
        endfor
        return citems
    endif
enddef

def ExtendUnique(dest: list<dict<any>>, src: list<dict<any>>): list<dict<any>>
    var found = {}
    for item in dest
        found[item.word] = 1
    endfor
    var items = dest->copy()
    for item in src
        if !found->has_key(item.word)
            items->add(item)
        endif
    endfor
    return items
enddef

def GetLength(items: list<dict<any>>, prefix: string): number
    try
        return items->reduce((sum, val) => sum + (val.word =~# $'^{prefix}' ? 1 : 0), 0)
    catch
        return 0
    endtry
enddef

def OtherBufMatches(items: list<dict<any>>, prefix: string): list<dict<any>>
    if GetLength(items, prefix) > options.maxCount || options.otherBuffersCount < 1
        return items
    endif
    var buffers = getbufinfo({ bufloaded: 1 })
    var curbufnr = bufnr('%')
    var Buflisted = (bufnr) => getbufinfo(bufnr)->get(0, {listed: false}).listed
    buffers = buffers->filter((_, v) => v.bufnr != curbufnr && Buflisted(v.bufnr))
    buffers->sort((v1, v2) => v1.lastused > v2.lastused ? -1 : 1)
    buffers = buffers->slice(0, options.otherBuffersCount)
    var citems = items->copy()
    for b in buffers
        citems = ExtendUnique(citems, BufWords(b.bufnr, prefix))
        if GetLength(citems, prefix) > options.maxCount
            break
        endif
    endfor
    return citems
enddef

# Search for http links in current buffer
def UrlMatches(base: string): list<dict<any>>
    var start = reltime()
    var timeout = options.timeout
    var linenr = 1
    var items = []
    var baselen = base->len()
    for line in getline(1, '$')
        var url = line->matchstr('\chttp\S\+')
        # url can have non-word characters like ~)( etc., (RFC3986) that need to be
        # escaped in a regex. Error prone. More robust way is to compare strings.
        if !url->empty() && url->strpart(0, baselen) ==? base
            items->add(url)
        endif
        # Check every 200 lines if timeout is exceeded
        if (timeout > 0 && linenr % 200 == 0 &&
                start->reltime()->reltimefloat() * 1000 > timeout)
            break
        endif
        linenr += 1
    endfor
    items->sort()->uniq()
    var kind = util.GetItemKindValue('URL')
    return items->map((_, v) => ({ word: v, abbr: v, kind: kind }))
enddef

# Using searchpos() is ~15% faster than gathering words by splitting lines and
# comparing each word for pattern.
def CurBufMatches(prefix: string): list<dict<any>>
    var icasepat = $'\c\<{prefix}\k*'
    var pattern = $'\<{prefix}'
    var searchStartTime = reltime()
    var timeout: number = options.timeout / 2

    def SearchWords(forward: bool): list<any>
        var [startl, startc] = [line('.'), col('.')]
        var [lnum, cnum] = [1, 1]
        var flags = forward ? 'W' : 'Wb'
        var words = []
        var found = {}
        var count = 0
        var Elapsed = (t) => float2nr(t->reltime()->reltimefloat() * 1000)
        try
            [lnum, cnum] = icasepat->searchpos(flags, 0, timeout)
        catch # a `~` in icasepat keyword (&isk) in txt file throws E33
            echom v:exception
            return []
        endtry
        while [lnum, cnum] != [0, 0]
            var [endl, endc] = icasepat->searchpos('ceW') # end of matching string
            const line = getline(lnum)
            const beginidx = line->charidx(cnum - 1)
            var mstr = line->strcharpart(beginidx, line->charidx(endc - 1) - beginidx + 1)
            if mstr != prefix && !found->has_key(mstr)
                found[mstr] = 1
                words->add([mstr, abs(lnum - startl)])
                try
                    if mstr =~# pattern
                        count += 1
                    endif
                catch
                endtry
            endif
            if (count >= options.maxCount) || searchStartTime->Elapsed() > timeout
                timeout = 0
                cursor([startl, startc])
                break
            endif
            if !forward
                cursor(lnum, cnum) # restore cursor, otherwise backward search loops
            endif
            [lnum, cnum] = icasepat->searchpos(flags, 0, timeout)
        endwhile
        timeout = max([0, timeout - searchStartTime->Elapsed()])
        cursor([startl, startc])
        return words
    enddef

    # Search backwards and forward
    var bwd = SearchWords(false)
    timeout += options.timeout / 2
    var fwd = SearchWords(true)
    var dist = {} # {word: distance}
    for word in bwd
        dist[word[0]] = word[1]
    endfor
    for word in fwd
        dist[word[0]] = dist->has_key(word[0]) ? min([dist[word[0]], word[1]]) : word[1]
    endfor
    fwd->filter((_, v) => v[1] == dist[v[0]])
    bwd->filter((_, v) => v[1] == dist[v[0]])
    var found = {}
    for word in fwd
        found[word[0]] = 1
    endfor
    bwd->filter((_, v) => !found->has_key(v[0])) # exclude word in both fwd and bwd with same dist

    # Merge the two lists
    var fwdlen = fwd->len()
    var bwdlen = bwd->len()
    var fwdidx = 0
    var bwdidx = 0
    var citems = []
    var kind = util.GetItemKindValue('Keyword')
    while fwdidx < fwdlen && bwdidx < bwdlen
        var wordf = fwd[fwdidx]
        var wordb = bwd[bwdidx]
        if wordf[1] < wordb[1]
            citems->add({ word: wordf[0], kind: kind })
            fwdidx += 1
        else
            citems->add({ word: wordb[0], kind: kind })
            bwdidx += 1
        endif
    endwhile
    while fwdidx < fwdlen
        var wordf = fwd[fwdidx]
        citems->add({ word: wordf[0], kind: kind })
        fwdidx += 1
    endwhile
    while bwdidx < bwdlen
        var wordb = bwd[bwdidx]
        citems->add({ word: wordb[0], kind: kind })
        bwdidx += 1
    endwhile

    var candidates: list<any> = []
    if !citems->empty()
        try
            candidates = citems->copy()->filter((_, v) => v.word =~# pattern)
        catch
        endtry
        if candidates->len() >= options.maxCount
            return candidates->slice(0, options.maxCount)
        endif
        if options.completionMatcher == 'icase'
            try
                candidates += citems->copy()->filter((_, v) => v.word !~# pattern)
            catch
            endtry
            if candidates->len() >= options.maxCount
                return candidates->slice(0, options.maxCount)
            endif
        endif
    endif
    return candidates
enddef

var previous = {prefix: '', completed: true}

export def Completor(findstart: number, base: string): any
    if findstart == 2
        return 1
    elseif findstart == 1
        var line = getline('.')->strpart(0, col('.') - 1)
        var prefix: string
        if options.urlComplete
            prefix = line->matchstr('\c\vhttp(s)?(:)?(/){0,2}\S+$')
        endif
        if prefix == '' && options.envComplete
            prefix = line->matchstr('$\zs\k\+$')
        endif
        if prefix == ''
            prefix = line->matchstr('\k\+$')
            if prefix == ''
                return -2
            endif
        endif
        if previous.prefix != '' && !previous.completed
            var plen = (previous.prefix)->len()
            if prefix->strpart(0, plen) == previous.prefix
                # if previous attempt was unsuccessful for the same prefix, do not try again
                previous.prefix = prefix
                return -2
            endif
        endif
        previous.prefix = prefix
        return line->len() - prefix->len() + 1
    endif

    if options->has_key('icase')  # legacy option
        options.completionMatcher = options.icase ? 'icase' : 'case'
    endif
    var candidates: list<dict<any>> = []
    if options.urlComplete && base =~? '^http'
        candidates += UrlMatches(base)
    endif
    if options.envComplete
        var line = getline('.')->strpart(0, col('.') - 1)
        if line =~ '$\k\+$'
            var kind = util.GetItemKindValue('EnvVariable')
            var envs = base->getcompletion('environment')->map((_, v) => ({ word: v, abbr: v, kind: kind }))
            candidates += envs
        endif
    endif
    if base =~ '^\k\+$' # not url or env complete
        if options.completionMatcher == 'fuzzy'
            candidates += BufWords(0, base, true)
        else
            candidates += CurBufMatches(base)
        endif
        if candidates->len() < options.maxCount
            candidates = OtherBufMatches(candidates, base)
        endif
        # remove items identical to what is already typed
        candidates->filter((_, v) => v.word !=# base)
        # remove item xxxyyy when it appears in the form of xxx|yyy (where '|' is the cursor)
        var postfix = getline('.')->matchstr('^\w\+', col('.') - 1)
        if !postfix->empty()
            var excluded = $'{base}{postfix}'
            candidates->filter((_, v) => v.word !=# excluded)
        endif
        # in 'txt' and 'help' files show camelcase as appropriate
        if &filetype =~ 'text\|help'
            if base =~ '^\l\+$'
                candidates->mapnew((_, v) => {
                    if v.word =~ '^\u\l\+$'
                        v.word = v.word->tolower()
                    endif
                    return v
                })
            elseif base =~ '^\u\l\+$'
                candidates->mapnew((_, v) => {
                    if v.word =~ '^\l\+$'
                        v.word = v.word->slice(0, 1)->toupper() .. v.word->slice(1)
                    endif
                    return v
                })
            endif
        endif
    endif
    if options.dup
        candidates->map((_, v) => v->extend({ dup: 1 }))
    endif

    previous.completed = !candidates->empty()
    return candidates->slice(0, options.maxCount)
enddef
