vim9script

import autoload '../autoload/abbrev.vim'
import autoload '../autoload/buffer.vim'
import autoload '../autoload/path.vim'
import autoload '../autoload/vimscript.vim'
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
	if !o->has_key('enabled') || o.enabled
	    var compl = eval($'{provider}.Completor')
	    completor.Register(provider, compl, ftypes, o->get('priority', priority))
	endif
    enddef
    Register('abbrev', ['*'], 10)
    Register('buffer', ['*'], 10)
    Register('path', ['*'], 11) # higher priority than buffer, so /xx/yy work
    Register('vimscript', ['vim'], 9)
    Register('dictionary', ['text', 'markdown'], 5)
    Register('vsnip', ['*'], 9)
    Register('lsp', ['*'], 8)
enddef

augroup VimCompleteLoaded | autocmd!
    autocmd User * ++once call RegisterPlugins()
augroup END

# Set vimcomplete plugin options from 'opts'.
def! g:VimCompleteOptionsSet(opts: dict<any>)
    for key in opts->keys()
	var newopts = opts[$'{key}']
	if newopts->has_key('maxCount')
	    newopts.maxCount = abs(newopts.maxCount)
	endif
	var o = eval($'{key}.options')
	o->extend(newopts)
    endfor
    # Re-register providers since priority could have changed
    RegisterPlugins()
enddef

