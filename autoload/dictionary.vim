vim9script

# /usr/share/dict/words is ~2M. Reading in the file took 33ms, and <c-x><c-k>
# for string 'za' took 62ms. Parsing each line into a list took 1.2 sec. Three
# options: 1) read in the file into a buffer and search it using searchpos(),
# 2) read file into a list and do binary search, 3) use external command
# 'look' which does binary search. 'look' maybe faster since Vim does not have
# to read the file. Other options are :vimgrep and :grep commands.

export var options: dict<any> = {
    icase: false,
}

var dictbufs = {}

const MaxCount = 10

# Create a readonly, unlisted buffer for each dictionary file so we don't have
# to read from disk repeatedly. This is a one-time thing, took 45ms for a 2M
# dictionary file. 
# Return a list of buffer numbers of dictionary files.
def GetDict(): list<any>
    var bufnr = bufnr() # bufnr of active buffer
    if dictbufs->has_key(bufnr)
	return dictbufs[bufnr]
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
	dictbufs[bufnr] = dictbuf
    endif
    return dictbuf
enddef

# Binary search dictionary buffer. Use getbufline() instead of creating a list
# (time consuming).
def GetWords(prefix: string, bufnr: number): list<string>
    var lidx = 1
    var binfo = getbufinfo(bufnr)
    if binfo == []
	return []
    endif
    var ridx = binfo[0].linecount
    while lidx + 1 < ridx
	var mid: number = (ridx + lidx) / 2
	var words = bufnr->getbufoneline(mid)->split() # in case line has >1 word, split
	if words->empty()
	    return [] # error in dictionary file
	endif
	if prefix->tolower() < words[0]->tolower()
	    ridx = mid
	else
	    lidx = mid
	endif
    endwhile
    lidx = max([1, lidx - MaxCount])
    ridx = min([binfo[0].linecount, ridx + MaxCount])
    var items = []
    var pattern = options.icase ? $'\c^{prefix}' : $'\C^{prefix}'
    for line in bufnr->getbufline(lidx, ridx)
	for word in line->split()
	    if word =~ pattern
		items->add(word)
	    endif
	endfor
    endfor
    return items
enddef

export def Completor(findstart: number, base: string): any
    if findstart == 2
	return 1
    elseif findstart == 1
	var line = getline('.')->strpart(0, col('.') - 1)
	var prefix = line->matchstr('\a\+$')
	if prefix == '' || prefix->len() < 2
	    return -2
	endif
	return col('.') - prefix->strlen()
    endif

    var prefix = base
    var items = []
    for bufnr in GetDict()
	items->extend(GetWords(prefix, bufnr))
    endfor
    var found = {}
    var candidates = []
    for item in items # remove duplicates
	if !found->has_key(item)
	    found[item] = 1
	    candidates->add(item)
	endif
    endfor
    candidates = candidates->sort()->slice(0, MaxCount)
    if options.icase
	var camelcase = prefix =~# '^\u\U'
	if camelcase
	    candidates->map('toupper(v:val[0]) .. v:val[1:]')
	else
	    var uppercase = prefix =~# '^\u\+\$'
	    if uppercase
		candidates->map('toupper(v:val)')
	    endif
	endif
    endif
    var citems = []
    for candidate in candidates
	citems->add({
	    word: candidate,
	    kind: 'D',
	})
    endfor
    return citems
enddef
