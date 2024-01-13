vim9script

# /usr/share/dict/words is ~2M. Reading in the file took 33ms, and <c-x><c-k>
# for string 'za' took 62ms. Parsing each line into a list took 1.2 sec. Three
# options: 1) read in the file into a buffer and search it using searchpos(),
# 2) read file into a list and do binary search, 3) use external command
# 'look' which does binary search. 'look' maybe faster since Vim does not have
# to read the file. Other options are :vimgrep and :grep commands.

export var options: dict<any> = {
    enable: false,
    matcher: 'case', # 'case', 'ignorecase', 'smartcase', 'casematch'. not active when onlyWords is false.
    maxCount: 10,
    sortedDict: true,
    onlyWords: true, # [0-9z-zA-Z] if true, else any non-space char is allowed
    timeout: 0, # not implemented yet
    dup: false, # suppress duplicates
}

def SortedDict(): bool
    if options->has_key('properties') && options.properties->has_key(&filetype)
        return options.properties[$'{&filetype}'].sortedDict
    endif
    return options.sortedDict
enddef

def OnlyWords(): bool
    if options->has_key('properties') && options.properties->has_key(&filetype)
        return options.properties[$'{&filetype}'].onlyWords
    endif
    return options.onlyWords
enddef

var dictbufs = {}

# Create a readonly, unlisted buffer for each dictionary file so we don't have
# to read from disk repeatedly. This is a one-time thing, took 45ms for a 2M
# dictionary file on Macbook Air M1.
#
# Return a list of buffer numbers of dictionary files.
def GetDict(): list<any>
    var ftype = &filetype # filetype of active buffer
    if dictbufs->has_key(ftype)
        return dictbufs[ftype]
    endif
    if &dictionary == ''
        return []
    endif
    var dictbuf = []
    for d in &dictionary->split(',')
        var bnr = bufadd(d)
        bnr->bufload()
        setbufvar(bnr, "&buftype", 'nowrite')
        setbufvar(bnr, "&swapfile", 0)
        setbufvar(bnr, "&buflisted", 0)
        dictbuf->add(bnr)
    endfor
    if !dictbuf->empty()
        dictbufs[ftype] = dictbuf
    endif
    return dictbufs[ftype]
enddef

var dictwords: dict<any> = {} # dictionary file -> words

def GetWords(prefix: string, bufnr: number): dict<any>
    var startcol: number
    if options.timeout <= 0
        # read the whole dict buffer at once and cache it
        if !dictwords->has_key(bufnr)
            dictwords[bufnr] = []
            for line in bufnr->getbufline(1, '$')
                if line !~ '^\s*---'
                    # ignore comments a la https://github.com/vim-scripts/Pydiction
                    dictwords[bufnr]->extend(line->split()) # needed when line has >1 words
                endif
            endfor
        endif

        var items = []
        if OnlyWords()
            var pattern = (options.matcher == 'case') ? $'\C^{prefix}' : $'\c^{prefix}'
            items = dictwords[bufnr]->copy()->filter((_, v) => v =~ pattern)
            startcol = col('.') - prefix->strlen()
        else
            var prefixlen = prefix->len()
            items = dictwords[bufnr]->copy()->filter((_, v) => v->slice(0, prefixlen) == prefix)
            # check if we should return xxx from yyy.xxx
            var second_part = prefix->matchstr('\k\+$')
            if !second_part->empty() && second_part->len() < prefix->len()
                var first_part_len = prefix->len() - second_part->len()
                items->map((_, v) => v->slice(first_part_len))
                startcol = col('.') - second_part->strlen()
            else
                if items->empty()
                    var kwPrefix = prefix->matchstr('\k\+$')
                    items->extend(dictwords[bufnr]->copy()->filter((_, v) => v =~ $'\C^{kwPrefix}'))
                    startcol = col('.') - kwPrefix->strlen()
                endif
                startcol = col('.') - prefix->strlen()
            endif
        endif
        return { startcol: startcol, items: items }
    endif
    return { startcol: 0, items: [] } # not implemented
enddef

# Binary search dictionary buffer. Use getbufline() instead of creating a
# list (for efficiency).
def GetWordsBinarySearch(prefix: string, bufnr: number): dict<any>
    var lidx = 1
    var binfo = getbufinfo(bufnr)
    if binfo == []
        return { startcol: 0, items: [] }
    endif
    var ridx = binfo[0].linecount
    while lidx + 1 < ridx
        var mid: number = (ridx + lidx) / 2
        var words = bufnr->getbufoneline(mid)->split() # in case line has >1 word, split
        if words->empty()
            return { startcol: 0, items: [] } # error in dictionary file
        endif
        if prefix->tolower() < words[0]->tolower()
            ridx = mid
        else
            lidx = mid
        endif
    endwhile
    lidx = max([1, lidx - options.maxCount])
    ridx = min([binfo[0].linecount, ridx + options.maxCount])
    var items = []
    var pattern = (options.matcher == 'case') ? $'\C^{prefix}' : $'\c^{prefix}'
    for line in bufnr->getbufline(lidx, ridx)
        for word in line->split()
            if word =~ pattern
                items->add(word)
            endif
        endfor
    endfor
    var startcol = col('.') - prefix->strlen()
    return { startcol: startcol, items: items }
enddef

def GetCompletionItems(prefix: string): dict<any>
    var items = []
    var startcol: number = -1
    var dwords = {}
    if OnlyWords()
        for bufnr in GetDict()
            if SortedDict()
                dwords = GetWordsBinarySearch(prefix, bufnr)
            else
                dwords = GetWords(prefix, bufnr)
            endif
            items->extend(dwords.items)
            startcol = dwords.startcol
        endfor
    else # only one dictionary supported, since startcol can differ among dicts
        var dicts = GetDict()
        if !dicts->empty()
            dwords = GetWords(prefix, dicts[0])
            items->extend(dwords.items)
            startcol = dwords.startcol
        endif
    endif

    var candidates = []
    # remove duplicates
    var found = {}
    for item in items
        if !found->has_key(item)
            found[item] = 1
            candidates->add(item)
        endif
    endfor
    if OnlyWords()
        if options.matcher == 'casematch'
            var camelcase = prefix =~# '^\u\U'
            if camelcase
                candidates->map('toupper(v:val[0]) .. v:val[1 : ]')
            else
                var uppercase = prefix =~# '^\u\+$'
                if uppercase
                    candidates->map('toupper(v:val)')
                endif
            endif
        elseif options.matcher == 'smart'
            if prefix =~# '\u' # at least one uppercase letter
                var prefixlen = prefix->len()
                candidates->filter((_, v) => v->slice(0, prefixlen) == prefix)
            endif
        endif
    endif
    candidates = candidates->slice(0, options.maxCount)
    var citems = []
    for candidate in candidates
        citems->add({
            word: candidate,
            kind: 'D',
            dup: options.dup ? 1 : 0,
        })
    endfor
    return { startcol: startcol, items: citems }
enddef

var completionItems: dict<any> = {}

export def Completor(findstart: number, base: string): any
    if findstart == 2
        return 1
    elseif findstart == 1
        var line = getline('.')->strpart(0, col('.') - 1)
        var prefix = OnlyWords() ? line->matchstr('\w\+$') : line->matchstr('\S\+$')
        if prefix == ''
            return -2
        endif
        completionItems = GetCompletionItems(prefix)
        return completionItems.items->empty() ? -2 : completionItems.startcol
    endif
    return completionItems.items
enddef
