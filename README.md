#### Async Autocompletion Plugin for Vim

A lightweight autocompletion plugin written entirely in vim9script.

## Features

- Code completion using [LSP](https://github.com/yegappan/lsp)
- Snippet completion using [vsnip](https://github.com/hrsh7th/vim-vsnip)
- Buffer word completion
- Dictionary completion
- Dictionary (and next-word) completion using [ngrams](https://github.com/girishji/ngram-complete.vim)
- [Vimscript](https://github.com/girishji/vimscript-complete.vim) language completion (like LSP)
- Path completion
- Abbreviation completion

Each of the above completion options can be configured for specific file types.

In addition, completion items can be sorted based on:

- Recency
- Length of item
- Priority
- Locality of item (for buffer completion)
- Case match

For cmdline-mode completion (`/`, `?`, and `:`) see **[autosuggest](https://github.com/girishji/autosuggest.vim)** plugin.

## Requirements

- Vim >= 9.0

## Installation

Install using [vim-plug](https://github.com/junegunn/vim-plug).
```
vim9script
plug#begin()
Plug 'girishji/vimcomplete.vim'
plug#end()
```

Alternately,
```
call plug#begin()
Plug 'girishji/vimcomplete.vim'
call plug#end()
```

Or use Vim's builtin package manager.
```
$ mkdir -p $HOME/.vim/pack/downloads/opt
$ cd $HOME/.vim/pack/downloads/opt
$ git clone https://github.com/girishji/vimcomplete.git
```

If using builtin package manager, add the following line to your $HOME/.vimrc
file:

```
packadd vimcomplete
```

## Configuration

Autocompletion is not enabled by default. Enable it by invoking the command
`VimCompleteEnable` in $HOME/.vimrc. If you are using
[vim-plug](https://github.com/junegunn/vim-plug) enable by registering to `VimEnter`
event.

```
autocmd VimEnter * VimCompleteEnable
```

Another option is to enable the plugin selectively based on _file type_.
For example, enable autocompletion for _c_, _cpp_, _python_, _vim_, _text_, and _markdown_
files.

```
autocmd FileType c,cpp,python,vim,text,markdown VimCompleteEnable
```

Autocompletion items are sourced from builtin as well as external _modules_.
Following _sources_ are builtin: _lsp_, _buffer_, _dictionary_,
_path_, and _abbrev_.

*Note*: In order to use the builtin _lsp_ sourcing module [LSP
client](https://github.com/yegappan/lsp) need to be installed.

Following _sources_ are external to this plugin. See the links below for
installation and configuration instructions.

- Dictionary and next-word completion using [_ngram_](https://github.com/girishji/ngram-complete.vim)
- [_vimscript_](https://github.com/girishji/vimscript-complete.vim) language completion (like LSP)
- [_vsnip_](https://github.com/girishji/vsnip-complete.vim) snippet completion

Both completion _engine_ and sourcing _modules_ are fully configurable.
Builtin _sources_ are *not* activated (enabled) by default except for
_buffer_ and _path_ completion.

#### Completion Engine Options

Option|Type|Description
------|----|-----------
`sortByLength`|`Boolean`|Sort completion items based on length of autocompletion text. Default is `false`.
`recency`|`Boolean`|Show most recently chosen items at the top. Default is `true`.
`recentItemCount`|`Number`|Number of recent items to show at the top. Default is `5`.
`matchCase`|`Boolean`|Some sources return items that may not match the case of prefix being completed. Show items that match case with prefix at the top followed by other items. Default is `true`.
`kindName`|`Boolean`|Show the kind of completion as a full word (verbose) instead of a single letter. For example, show `[snippet]` instead of `S`. Default is `true`.
`shuffleEqualPriority`|`Boolean`|Items from equal priority _sources_ are arranged such that the first item from each _source_ appear at the top. Default is set to `false`.
`noNewlineInCompletion`|`Boolean`|`<Enter>` key in insert mode stops completion and inserts an `<Enter>`. Default is set to `false`.

#### Completion Sourcing Module Options

Following options are common to all completion sources.

Option|Type|Description
------|----|-----------
`enable`|`Boolean`|`true` to enable the source. Default is `false` for all builtin sources except _buffer_ and _path_ completion.
`maxCount`|`Number`|Number of completion items made available from the _source_. Default is `10`.
`priority`|`Number`|Higher priority items are shown at the top. Default is `10`.
`filetypes`|`List`|List of file-types to enable for a particular _source_. Default is `['*']` (all file-types), except for _dictionary_ _source_ which is set to `['text', 'markdown']`.

##### Buffer Source Options

_Buffer_ completion _source_ has additional options.

Option|Type|Description
------|----|-----------
`timeout`|`Number`|Maximum time spent searching for completion candidates in current buffer. Default is `100` milliseconds. If searching in multiple buffers additional 100 milliseconds is allocated. Search is aborted if any key is pressed.
`searchOtherBuffers`|`Boolean`|Search other listed buffers. Default is `true`.
`otherBuffersCount`|`Number`|Maximum number of other listed buffers to search. Default is `3`.
`icase`|`Boolean`|Ignore case when searching for completion candidates. Default is `true`.
`urlComplete`|`Boolean`|Complete http links in entirety. Useful when typing same url multiple times. Default is `false`.

Options are enabled using global function `g:VimCompleteOptionsSet()`. Here is
an example of how you can enable and configure completion sources.

```
vim9script
var options = {
    completor: { shuffleEqualPriority: true },
    buffer: { enable: true, priority: 10 },
    lsp: { enable: true, priority: 9 },
    vsnip: { enable: true, priority: 11 },
    ngram: {
        enable: true,
        priority: 10,
        bigram: false,
        filetypes: ['text', 'help', 'markdown'],
        filetypesComments: ['c', 'cpp', 'python', 'java'],
    },
}
autocmd VimEnter * g:VimCompleteOptionsSet(options)
```

#### Tab Completion

`<Tab>` and `<S-Tab>` keys can be mapped to select autocompletion items. By
default `<C-N>` and `<C-P>` select the menu items.

```
g:vimcomplete_tab_enable = 1
```

## Commands 

You can enable or disable the plugin anytime using commands.

```
:VimCompleteEnable
:VimCompleteDisable
```

Following command shows a list of completion sources enabled for the current
buffer.

```
:VimCompleteCompletors
```

## Writing Your Own Extensions

A good place to start is by looking at the implementation of external
plugins [Vimscript](https://github.com/girishji/vimscript-complete.vim) completion,
[ngrams](https://github.com/girishji/ngram-complete.vim), and
[ngrams-viewer](https://github.com/girishji/ngramview-complete.vim) (spawns a
new process to handle http requests).

The Completion engine uses similar interface as Vim's
[complete-functions](https://vimhelp.org/insert.txt.html#complete-functions)
except that the function is called in three different ways (instead of two):

- First the function is called to find the start of the text to be completed.
- Next the function is called to check if completion candidates are available.
- Later the function is called to actually find the matches.

The first and last invocation are identical to Vim's
[complete-functions](https://vimhelp.org/insert.txt.html#complete-functions).
On the second invocation the arguments are:

- findstart: 2
- base:	empty

The function must return `true` or `false` indicating whether completion
candidates are ready. Only when this return value is `true` will the function
invoked for the third time to get the actual matches. This step is necessary
for asynchronous completion.

It does not matter what the name of the completion function is but it
should take two arguments `findstart: Number` and `base: String` and return
`<any>`. This function should be registered with completion engine by calling
`vimcompletor.Register()` function. The `User` event of type
`VimCompleteLoaded` can be used to time the registration.

When the user sets options through configuration file a `User` event with type
`VimCompleteOptionsChanged` is issued. The plugin should register for this
event and update its internal state appropriately.

## Demo

[![asciicast](https://asciinema.org/a/MIlCdPGFd2OK7SQvFQptrSX5D.svg)](https://asciinema.org/a/MIlCdPGFd2OK7SQvFQptrSX5D)

## Contributing

Pull requests are welcome.

## Similar Vim Plugins

- [asyncomplete](https://github.com/prabirshrestha/asyncomplete.vim)
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
