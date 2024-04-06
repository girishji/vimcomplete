vim9script

# Interface to https://github.com/yegappan/lsp through omnifunc

export var options: dict<any> = {
    enable: true,
    maxCount: 10,
    keywordOnly: false, # 'false' will complete after '.' in 'builtins.'
    dup: true,
}

export def Setup()
    # Turn off LSP client even if this module is disabled. Otherwise LSP will
    # open a separate popup window with completions.
    if exists('*g:LspOptionsSet')
        var lspOpts = {
            useBufferCompletion: false,
            completionTextEdit: true,  # https://github.com/girishji/vimcomplete/issues/37
            snippetSupport: true, # snippets from lsp server
            vsnipSupport: false,
            autoComplete: false,
            omniComplete: true,
        }
        if options->has_key('completionMatcher')
            lspOpts->extend({completionMatcher: options.completionMatcher})
        endif
        g:LspOptionsSet(lspOpts)
    endif
enddef

export def Completor(findstart: number, base: string): any
    if !exists('*g:LspOmniFunc')
        return -2 # cancel but stay in completion mode
    endif
    var line = getline('.')->strpart(0, col('.') - 1)
    if line =~ '\s$'
        return -2
    endif
    if options.keywordOnly
        var prefix = line->matchstr('\k\+$')
        if prefix->empty()
            return -2
        endif
    endif
    if findstart == 1
        var startcol = g:LspOmniFunc(findstart, base)
        return startcol < 0 ? startcol : startcol + 1
    elseif findstart == 2
        return !g:LspOmniCompletePending()
    endif
    var items = g:LspOmniFunc(findstart, base)
    # items->filter((_, v) => v.word != base)
    items = items->slice(0, options.maxCount)
    if !options.dup
        items->map((_, v) => v->extend({ dup: 0 }))
    endif
    return items
enddef

if get(g:, 'loaded_lsp', false)
    import autoload 'lsp/buffer.vim' as buf
    # Return trigger kind and trigger char. If completion trigger is not a keyword
    # and not one of the triggerCharacters, return -1.
    # Trigger kind is 1 for keyword and 2 for trigger char initiated completion.
    export def GetTriggerKind(): number
        var lspserver: dict<any> = buf.CurbufGetServerChecked('completion')
        var triggerKind: number = 1
        var line: string = getline('.')
        var cur_col = charcol('.')
        if line[cur_col - 2] !~ '\k'
            var trigChars = lspserver.completionTriggerChars
            var trigidx = trigChars->index(line[cur_col - 2])
            if trigidx == -1
                triggerKind = -1
            else
                triggerKind = 2
            endif
        endif
        return triggerKind
    enddef
else
    export def GetTriggerKind(): number
        return -1
    enddef
endif

