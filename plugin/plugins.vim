vim9script

import autoload '../autoload/abbrev.vim'
import autoload '../autoload/buffer.vim'
import autoload '../autoload/path.vim'
import autoload '../autoload/dictionary.vim'
import autoload '../autoload/vsnip.vim'
import autoload '../autoload/lsp.vim'

# Enable completion in buffer loaded by default (which has no filetype)
import '../autoload/completor.vim'
if get(g:, 'vimcomplete_default_buf_enable')
    completor.Enable()
endif

def RegisterPlugins()
    completor.ClearRegistered()
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
    Register('buffer', ['*'], 10)
    Register('path', ['*'], 11) # higher priority than buffer, so /xx/yy work
    Register('dictionary', ['text', 'markdown'], 5)
    Register('vsnip', ['*'], 9)
    Register('lsp', ['*'], 8)
enddef

autocmd User VimCompleteLoaded ++once call RegisterPlugins()

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
enddef

