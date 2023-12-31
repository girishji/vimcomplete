vim9script

import '../autoload/completor.vim'

export def Register(name: string, Completor: func, ftype: list<string>, priority: number)
    completor.Register(name, Completor, ftype, priority)
enddef

export def Unregister(name: string)
    completor.Unregister(name)
enddef

export def GetOptions(provider: string): dict<any>
    return completor.alloptions->get(provider, {})
enddef
