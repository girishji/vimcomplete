vim9script

# Autocomplete file path

import autoload './util.vim'

export var options: dict<any> = {
    enable: true,
    bufferRelativePath: true,
    groupDirectoriesFirst: false,
    showPathSeparatorAtEnd: false,
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
        if prefix->empty() || prefix =~ '?$' || prefix !~ (has('unix') || &shellslash ? '/' : '\')
            return -2
        endif
        return col('.') - prefix->strlen()
    endif

    var citems = []
    var cwd: string = ''
    var sep: string = has('win32') && !&shellslash ? '\' : '/'
    try
        if options.bufferRelativePath && expand('%:h') !=# '.' # not already in buffer dir
            # change directory to get completions for paths relative to current buffer dir
            cwd = getcwd()
            execute 'cd ' .. expand('%:p:h')
        endif
        var completions = getcompletion(base, 'file', 1)
        def IsDir(v: string): bool
            return isdirectory(fnamemodify(v, ':p'))
        enddef
        if options.groupDirectoriesFirst
            completions = completions->copy()->filter((_, v) => IsDir(v)) +
                completions->copy()->filter((_, v) => !IsDir(v))
        endif
        for item in completions
            var citem = item
            var itemlen = item->len()
            var isdir = IsDir(item)
            if isdir && item[itemlen - 1] == sep
                citem = item->slice(0, itemlen - 1)
            endif
            citems->add({
                word: citem,
                abbr: options.showPathSeparatorAtEnd ? item : citem,
                kind: isdir ? util.GetItemKindValue('Folder') : util.GetItemKindValue('File'),
                kind_hlgroup: isdir ? util.GetKindHighlightGroup('Folder') : util.GetKindHighlightGroup('File'),
            })
        endfor
    catch # on MacOS it does not complete /tmp/* (throws E344, looks for /private/tmp/...)
        echom v:exception
    finally
        if !cwd->empty()
            execute $'cd {cwd}'
        endif
    endtry
    return citems
enddef
