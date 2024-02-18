if !has('vim9script') ||  v:version < 900
    " Needs Vim version 9.0 and above
    finish
endif

vim9script

import autoload '../autoload/abbrev.vim'
import autoload '../autoload/buffer.vim'
import autoload '../autoload/path.vim'
import autoload '../autoload/dictionary.vim'
import autoload '../autoload/lsp.vim'
import autoload '../autoload/omnifunc.vim'
import autoload '../autoload/vimscript.vim'
import autoload '../autoload/vsnip.vim'
import autoload '../autoload/util.vim'
import '../autoload/completor.vim'

def RegisterPlugins()
    def Register(provider: string, ftypes: list<string>, priority: number)
        var o = eval($'{provider}.options')
        if !o->has_key('enable') || o.enable
            var compl = eval($'{provider}.Completor')
            completor.Register(provider, compl, o->get('filetypes', ftypes), o->get('priority', priority))
        else
            completor.Unregister(provider)
        endif
    enddef
    Register('abbrev', ['*'], 10)
    Register('buffer', ['*'], 12)
    Register('path', ['*'], 13) # higher priority than buffer, so /xx/yy work
    Register('dictionary', ['text', 'markdown'], 8)
    Register('omnifunc', ['python', 'javascript'], 8)
    Register('vimscript', ['vim'], 10)
    Register('vsnip', ['*'], 11)
    util.LspCompletionKindsSetDefault()
enddef

def RegisterLsp()
    # Note: When this function is called from LspAttached event
    # g:LspServerRunning() is false. But later when called from
    # g:VimCompleteOptionsSet() this variable becomes true.
    var o = lsp.options
    if (!o->has_key('enable') || o.enable) && exists('*g:LspServerRunning')
        if o->has_key('filetypes') && !o.filetypes->empty()
            completor.Register('lsp', lsp.Completor, o.filetypes,  o->get('priority', 10))
        elseif g:LspServerRunning(&ft)
            completor.Register('lsp', lsp.Completor, [&ft],  o->get('priority', 10))
        endif
    else
        completor.Unregister('lsp')
    endif
enddef

autocmd User VimCompleteLoaded ++once call RegisterPlugins()
autocmd User LspAttached call RegisterLsp()
autocmd VimEnter * lsp.Setup()


# Set vimcomplete plugin options from 'opts'.
def! g:VimCompleteOptionsSet(opts: dict<any>)
    completor.alloptions = opts->copy()
    for key in opts->keys()
        var newopts = completor.alloptions[$'{key}']
        if newopts->has_key('maxCount')
            newopts.maxCount = abs(newopts.maxCount)
        endif
        if !getscriptinfo({ name: $'vimcomplete/autoload/{key}' })->empty()
            var o = eval($'{key}.options')
            o->extend(newopts)
        endif
    endfor
    # Notify external completion providers that options have changed
    if exists('#User#VimCompleteOptionsChanged')
        :doau <nomodeline> User VimCompleteOptionsChanged
    endif
    # Re-register providers since priority could have changed
    RegisterPlugins()
    RegisterLsp()
enddef

def! g:VimCompleteOptionsGet(): dict<any>
    return completor.options->copy()
enddef
