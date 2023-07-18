vim9script

import '../autoload/abbrev.vim'
import '../autoload/buffer.vim'
import '../autoload/path.vim'
import '../autoload/vimscript.vim'
import '../autoload/dictionary.vim'
import '../autoload/vssnip.vim'
import '../autoload/lsp.vim'

# Enable completion in buffer loaded by default (has no filetype)
import '../autoload/completor.vim'
completor.Enable()
