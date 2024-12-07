vim9script

import autoload './util.vim'

# /usr/share/dict/words is ~2M. Reading in the file took 33ms, and <c-x><c-k>
# for string 'za' took 62ms. Parsing each line into a list took 1.2 sec. Three
# options: 1) read in the file into a buffer and search it using searchpos(),
# 2) read file into a list and do binary search, 3) use external command
# 'look' which does binary search. 'look' maybe faster since Vim does not have
# to read the file. Other options are :vimgrep and :grep commands.

# Note: Sorted dictionaries cannot have empty lines

export var options: dict<any> = {
    enable: false,
    matcher: 'case', # 'case', 'ignorecase'. active for sortedDict or onlyWords is true,
    maxCount: 10,
    sortedDict: true,
    onlyWords: true, # [0-9z-zA-Z] if true, else any non-space char is allowed (sorted=false assumed)
    commentStr: '---',
    triggerWordLen: 0,
    timeout: 0, # not implemented yet
    dup: false, # suppress duplicates
    matchStr: '\k\+$',
    matchAny: false,
    info: false,  # Whether 'info' popup needs to be populated
}

def GetProperty(s: string): any
    if options->has_key('properties') && options.properties->has_key(&filetype)
            && options.properties->get(&filetype)->has_key(s)
        return options.properties->get(&filetype)->get(s)
    endif
    return options->get(s)
enddef

def MatchStr(): string
    return GetProperty('matchStr')
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

def TriggerWordLen(): number
    return GetProperty('triggerWordLen')
enddef

def Info(): bool
    return GetProperty('info')
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
            var word = null_string
            var info = []
            var has_info = Info()
            for line in bufnr->getbufline(1, '$')
                if line !~ $'^\s*{CommentStr()}' # ignore comments (https://github.com/vim-scripts/Pydiction)
                    if has_info
                        if line =~ '^\%(\s\+\|$\)'  # info document
                            info->add(line->substitute('^\s\+', '', ''))
                        else
                            if word != null_string
                                dictwords[bufnr]->add({word: word}->extend(info != [] ? {info: info->join("\n")} : {}))
                            endif
                            word = line
                            info = []
                        endif
                    elseif !line->empty()
                        dictwords[bufnr]->add({word: line})
                    endif
                endif
            endfor
            if has_info && word != null_string
                dictwords[bufnr]->add({word: word}->extend(info != [] ? {info: info->join("\n")} : {}))
            endif
        endif

        var items = []
        if OnlyWords()
            var pat = (options.matcher == 'case') ? $'\C^{prefix}' : $'\c^{prefix}'
            items = dictwords[bufnr]->copy()->filter((_, v) => v.word =~ pat)
            startcol = col('.') - prefix->strlen()
        else
            var prefix_kw = prefix->matchstr(MatchStr())
            if prefix_kw->len() < prefix->len()
                # Do not pattern match, but compare (equality) instead.
                var prefixlen = prefix->len()
                items = dictwords[bufnr]->copy()->filter((_, v) => v.word->strpart(0, prefixlen) == prefix)
                # We should return xxx from yyy.xxx.
                var first_part_len = prefix->len() - prefix_kw->len()
                items->map((_, v) => v->strpart(first_part_len))
                startcol = col('.') - prefix_kw->strlen()
            elseif !prefix_kw->empty()
                try
                    items = dictwords[bufnr]->copy()->filter((_, v) => v.word =~# $'^{prefix}')
                    # Match 'foo' in 'barfoobaz'.
                    # items += dictwords[bufnr]->copy()->filter((_, v) => v.word =~# $'^.\{{-}}{prefix}')
                    startcol = col('.') - prefix_kw->strlen()
                catch
                endtry
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
        if prefix == words[0]->strpart(0, prefixlen)
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
        if prefix == line->strpart(0, prefixlen)
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
    var items = dwords.items
    if items->empty()
        return { startcol: 0, items: [] }
    endif
    startcol = dwords.startcol
    var candidates = []
    # remove duplicates
    var found = {}
    for item in items
        if !found->has_key(item.word)
            found[item.word] = 1
            candidates->add(item)
        endif
    endfor
    candidates = candidates->slice(0, options.maxCount)
    var citems = []
    for cand in candidates
        citems->add({
            word: cand.word,
            kind: util.GetItemKindValue('Dictionary'),
            kind_hlgroup: util.GetKindHighlightGroup('Dictionary'),
            dup: options.dup ? 1 : 0,
        }->extend(cand->has_key('info') ? {info: cand.info} : {}))
    endfor
    return { startcol: startcol, items: citems }
enddef

var completionItems: dict<any> = {}

export def Completor(findstart: number, base: string): any
    if findstart == 2
        return 1
    elseif findstart == 1
        var line = getline('.')->strpart(0, col('.') - 1)
        var prefix: string
        if OnlyWords()
            prefix = line->matchstr('\w\+$')
        else
            prefix = line->matchstr(MatchStr())
            if prefix == null_string && options.matchAny
                prefix = line->matchstr('\S\+$')
            endif
        endif
        if prefix == '' ||
                (TriggerWordLen() > 0 && prefix->len() < TriggerWordLen())
            return -2
        endif
        completionItems = GetCompletionItems(prefix)
        return completionItems.items->empty() ? -2 : completionItems.startcol
    endif
    return completionItems.items
enddef
