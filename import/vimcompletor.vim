vim9script

import '../autoload/completor.vim'

export def Register(name: string, Completor: func, ftype: list<string>, priority: number)
    completor.Register(name, Completor, ftype, priority)
enddef
