vim9script

# Completion from current buf

# XXX
# Completion is based on:
# 1) Frequency: How close

# Completion candidates are sorted according to locality (how close they are to
# cursor). Case sensitive matches are preferred to case insensitive and partial
# matches. If user type 'fo', then 'foo' appears before 'Foo' and 'barfoo'.

export var options: dict<any> = {
    Timeout: 100,
    MaxCount: 10,
}

# Using searchpos() is ~15% faster than gathering words by splitting lines and
# comparing each word for pattern.
export def Completor(findstart: number, base: string): any
    if findstart == 2
	return 1
    elseif findstart == 1
	var line = getline('.')->strpart(0, col('.') - 1)
	var prefix = line->matchstr('\k\+$')
	if prefix == ''
	    return -2
	endif
	return line->len() - prefix->len() + 1
    endif

    var prefix = base
    var pattern = $'\c\<{prefix}\k*'
    var icasepat = $'\<{prefix}'
    var searchStartTime = reltime()
    var timeout: number = options.Timeout / 2

    def SearchWords(forward: bool): list<any>
	var [startl, startc] = [line('.'), col('.')]
	var [lnum, cnum] = [1, 1]
	var flags = forward ? 'W' : 'Wb'
	var words = []
	var found = {}
	var count = 0
	var Elapsed = (t) => float2nr(t->reltime()->reltimefloat() * 1000)
	[lnum, cnum] = pattern->searchpos(flags, 0, timeout)
	while [lnum, cnum] != [0, 0]
	    var [endl, endc] = pattern->searchpos('ceW') # end of matching string
	    var mstr = getline(lnum)->strpart(cnum - 1, endc - cnum + 1)
	    if mstr != prefix && !found->has_key(mstr)
		found[mstr] = 1
		words->add([mstr, abs(lnum - startl)])
		if mstr =~# icasepat
		    count += 1
		endif
	    endif
	    if (count >= options.MaxCount) || searchStartTime->Elapsed() > timeout
		timeout = 0
		cursor([startl, startc])
		break
	    endif
	    if !forward
		cursor(lnum, cnum) # restore cursor, otherwise backward search loops
	    endif
	    [lnum, cnum] = pattern->searchpos(flags, 0, timeout)
	endwhile
	timeout = max([0, timeout - searchStartTime->Elapsed()])
	cursor([startl, startc])
	return words
    enddef

    # Search backwards and forward
    var bwd = SearchWords(false)
    timeout += options.Timeout / 2
    var fwd = SearchWords(true)
    var dist = {}
    for word in bwd
	dist[word[0]] = word[1]
    endfor
    for word in fwd
	dist[word[0]] = dist->has_key(word[0]) ? min([dist[word[0]], word[1]]) : word[1]
    endfor
    if dist->empty()
	return []
    endif

    # Merge the two lists
    var fwdlen = fwd->len()
    var bwdlen = bwd->len()
    var fwdidx = 0
    var bwdidx = 0
    var citems = []
    while fwdidx < fwdlen && bwdidx < bwdlen
	var wordf = fwd[fwdidx]
	if wordf[1] != dist[wordf[0]]
	    fwdidx += 1
	    continue
	endif
	var wordb = bwd[bwdidx]
	if wordb[1] != dist[wordb[0]]
	    bwdidx += 1
	    continue
	endif
	if wordf[1] < wordb[1]
	    citems->add({ word: wordf[0], kind: 'B' })
	    fwdidx += 1
	else
	    citems->add({ word: wordb[0], kind: 'B' })
	    bwdidx += 1
	endif
    endwhile
    while fwdidx < fwdlen
	var wordf = fwd[fwdidx]
	citems->add({ word: wordf[0], kind: 'B' })
	fwdidx += 1
    endwhile
    while bwdidx < bwdlen
	var wordb = bwd[bwdidx]
	citems->add({ word: wordb[0], kind: 'B' })
	bwdidx += 1
    endwhile

    if citems->empty()
	return []
    endif
    var candidates = citems->copy()->filter((_, v) => v.word =~# icasepat)
    if candidates->len() >= options.MaxCount
	return candidates->slice(0, options.MaxCount)
    endif
    candidates += citems->copy()->filter((_, v) => v.word !~# icasepat)
    return candidates->slice(0, options.MaxCount)
enddef
