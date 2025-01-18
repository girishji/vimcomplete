if !has('vim9script') ||  v:versionlong < 9000196
    " Needs Vim version 9.0.0196 and above
    finish
endif

vim9script

import autoload '../autoload/vimcomplete/abbrev.vim'
import autoload '../autoload/vimcomplete/buffer.vim'
import autoload '../autoload/vimcomplete/path.vim'
import autoload '../autoload/vimcomplete/dictionary.vim'
import autoload '../autoload/vimcomplete/lsp.vim'
import autoload '../autoload/vimcomplete/omnifunc.vim'
import autoload '../autoload/vimcomplete/vimscript.vim'
import autoload '../autoload/vimcomplete/vsnip.vim'
import autoload '../autoload/vimcomplete/tmux.vim'
import autoload '../autoload/vimcomplete/tag.vim'
import autoload '../autoload/vimcomplete/util.vim'
import autoload '../autoload/vimcomplete/completor.vim'

def RegisterAddons()
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
    Register('omnifunc', ['*'], 8)
    Register('vimscript', ['vim'], 10)
    Register('vsnip', ['*'], 11)
    Register('tmux', ['*'], 8)
    Register('tag', ['*'], 8)
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

autocmd User VimCompleteLoaded ++once RegisterAddons() | util.InitKindHighlightGroups()
autocmd User LspAttached RegisterLsp()
autocmd VimEnter * lsp.Setup()

# Set vimcomplete plugin options from 'opts'.
def! g:VimCompleteOptionsSet(opts: dict<any>)
    completor.SetOptions(opts)
    for [key, newopts] in opts->items()
        if exists($'{key}.options') == 1
            var o = eval($'{key}.options')
            o->extend(newopts)
        else
            echoerr $'vimcomplete: "{key}" key in the options is invalid.'
        endif
    endfor
    # Notify external completion providers that options have changed
    if exists('#User#VimCompleteOptionsChanged')
        silent! doautocmd <nomodeline> User VimCompleteOptionsChanged
    endif
    # Re-register providers since priority could have changed
    RegisterAddons()
    RegisterLsp()
enddef

def! g:VimCompleteInfoWindowOptionsSet(opts: dict<any>)
    util.info_popup_options->extend(opts)
enddef

# Legacy -- remove this function eventually
def! g:VimCompleteInfoPopupOptionsSet(opts: dict<any>)
    util.info_popup_options->extend(opts)
enddef

def! g:VimCompleteOptionsGet(): dict<any>
    return completor.options->copy()
enddef
