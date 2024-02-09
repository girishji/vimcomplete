vim9script

# Autocomplete file path

import autoload 'util.vim'

export var options: dict<any> = {
    enable: true,
    bufferRelativePath: true,
}

export def Completor(findstart: number, base: string): any
    if findstart == 2
        return 1
    elseif findstart == 1
        var line = getline('.')->strpart(0, col('.') - 1)
        var prefix = line->matchstr('\f\+$')
        if !prefix->empty() &&
                !(line->matchstr('\c\vhttp(s)?(:)?(/){0,2}\S+$')->empty())
            return -2
        endif
        if prefix->empty() || prefix =~ '?$' || prefix !~ (has('unix') ? '/' : '\')
            return -2
        endif
        return col('.') - prefix->strlen()
    endif

    var citems = []
    var cwd: string = ''
    var sep: string = has('win32') ? '\' : '/'
    try
        if options.bufferRelativePath && expand('%:h') !=# '.' # not already in buffer dir
            # change directory to get completions for paths relative to current buffer dir
            cwd = getcwd()
            :exec 'cd ' .. expand('%:p:h')
        endif
        var Fkind = util.GetItemKindValue('Folder')
        var fkind = util.GetItemKindValue('File')
        for item in getcompletion(base, 'file', 1)
            var citem = item
            var itemlen = item->len()
            var isdir = isdirectory(fnamemodify(item, ':p'))
            if isdir && item[itemlen - 1] == sep
                citem = item->slice(0, itemlen - 1)
            endif
            citems->add({
                word: citem,
                abbr: item,
                kind: isdir ? Fkind : fkind,
            })
        endfor
    catch # on MacOS it does not complete /tmp/* (throws E344, looks for /private/tmp/...)
        echom v:exception
    finally
        if !cwd->empty()
            :exec $'cd {cwd}'
        endif
    endtry
    return citems
enddef
