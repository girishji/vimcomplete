vim9script

import autoload 'util.vim'

# /usr/share/dict/words is ~2M. Reading in the file took 33ms, and <c-x><c-k>
# for string 'za' took 62ms. Parsing each line into a list took 1.2 sec. Three
# options: 1) read in the file into a buffer and search it using searchpos(),
# 2) read file into a list and do binary search, 3) use external command
# 'look' which does binary search. 'look' maybe faster since Vim does not have
# to read the file. Other options are :vimgrep and :grep commands.

# Note: Sorted dictionaries cannot have empty lines

export var options: dict<any> = {
    enable: false,
    matcher: 'case', # 'case', 'ignorecase', 'smartcase', 'casematch'. not active when onlyWords is false.
    maxCount: 10,
    sortedDict: true,
    onlyWords: true, # [0-9z-zA-Z] if true, else any non-space char is allowed
    commentStr: '---',
    timeout: 0, # not implemented yet
    dup: false, # suppress duplicates
}

def GetProperty(s: string): any
    if options->has_key('properties') && options.properties->has_key(&filetype)
            && options.properties->get(&filetype)->has_key(s)
        return options.properties->get(&filetype)->get(s)
    endif
    return options->get(s)
enddef

def CommentStr(): string
    return GetProperty('commentStr')
enddef

def OnlyWords(): bool
    return GetProperty('onlyWords')
enddef

def SortedDict(): bool
    return GetProperty('sortedDict')
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
                if line->empty()
                    continue
                endif
                if line !~ $'^\s*{CommentStr()}'
                    # ignore comments (like in https://github.com/vim-scripts/Pydiction)
                    dictwords[bufnr]->add(line)
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
# - Makes sense for only case match, since if a dictionary has both upper case and
#   lower case letters they could occur far apart.
# - Only one word per line
def GetWordsBinarySearch(prefix: string, bufnr: number): dict<any>
    var lidx = 1
    var binfo = getbufinfo(bufnr)
    if binfo == []
        return { startcol: 0, items: [] }
    endif
    var prefixlen = prefix->strlen()
    var ridx = binfo[0].linecount
    while lidx + 1 < ridx
        var mid: number = (ridx + lidx) / 2
        var words: list<string>
        var line = bufnr->getbufoneline(mid)
        words = line->split() # in case line has >1 word, split
        if words->empty()
            echoerr '(vimcomplete) error: Dictionary has empty line'
            return { startcol: 0, items: [] } # error in dictionary file
        endif
        if prefix == words[0]->slice(0, prefixlen)
            lidx = mid
            ridx = mid
            break
        endif
        if prefix < words[0]
            ridx = mid
        else
            lidx = mid
        endif
    endwhile
    lidx = max([1, lidx - options.maxCount])
    ridx = min([binfo[0].linecount, ridx + options.maxCount])
    var items = []
    for line in bufnr->getbufline(lidx, ridx)
        if prefix == line->slice(0, prefixlen)
            items->add(line)
        endif
    endfor
    var startcol = col('.') - prefixlen
    return { startcol: startcol, items: items }
enddef

def GetCompletionItems(prefix: string): dict<any>
    var startcol: number = -1
    var dwords = {}
    if SortedDict()
        for bufnr in GetDict()
            if dwords->empty()
                dwords = GetWordsBinarySearch(prefix, bufnr)
            else
                dwords.items->extend(GetWordsBinarySearch(prefix, bufnr).items)
            endif
        endfor
    else # only one dictionary supported, since startcol can differ among dicts
        var dicts = GetDict()
        if !dicts->empty()
            dwords = GetWords(prefix, dicts[0])
        endif
    endif
    if dwords->empty()
        return { startcol: 0, items: [] }
    endif
    var items = dwords.items
    startcol = dwords.startcol

    var candidates = []
    # remove duplicates
    var found = {}
    var kind = util.GetItemKindValue('Text')
    for item in items
        if !found->has_key(item)
            found[item] = 1
            candidates->add(item)
        endif
    endfor
    candidates = candidates->slice(0, options.maxCount)
    var citems = []
    for candidate in candidates
        citems->add({
            word: candidate,
            kind: kind,
            dup: options.dup ? 1 : 0,
        })
    endfor
    return { startcol: startcol, items: citems }
enddef

var completionItems: dict<any> = {}

var empty_at_last_str = ''
export def Completor(findstart: number, base: string): any
    if findstart == 2
        return 1
    elseif findstart == 1
        if empty_at_last_str is base
            return -2
        endif
        var line = getline('.')->strpart(0, col('.') - 1)
        var prefix = OnlyWords() ? line->matchstr('\w\+$') : line->matchstr('\S\+$')
        if prefix == ''
            empty_at_last_str = base
            return -2
        endif
        empty_at_last_str = ''
        completionItems = GetCompletionItems(prefix)
        return completionItems.items->empty() ? -2 : completionItems.startcol
    endif
    return completionItems.items
enddef
