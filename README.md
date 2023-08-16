#### Async Autocompletion Plugin for Vim

A lightweight async autocompletion plugin written entirely in vim9script.

## Features

- [Code completion](https://github.com/girishji/lsp-complete.vim) using [LSP](https://github.com/yegappan/lsp)
- [Snippet completion](https://github.com/girishji/vsnip-complete.vim) using [vsnip](https://github.com/hrsh7th/vim-vsnip)
- Buffer word completion (with timers)
- Vim's [omnifuc](https://github.com/girishji/omnifunc-complete.vim) language completion
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

Autocompletion items are sourced from builtin as well as external _modules_.
Following _sources_ are builtin: _buffer_, _dictionary_, _path_, and _abbrev_.

Following _sources_ are external to this plugin. See the links below for
installation and configuration instructions.

- _LSP_ based [code completion](https://github.com/girishji/lsp-complete.vim)
- Vim's _omnifunc_ based [code completion](https://github.com/girishji/omnifunc-complete.vim)
- Dictionary and next-word completion using [_ngram_](https://github.com/girishji/ngram-complete.vim)
- _vimscript_ [language completion](https://github.com/girishji/vimscript-complete.vim) (like LSP)
- _vsnip_ [snippet completion](https://github.com/girishji/vsnip-complete.vim)

Both completion _engine_ and source provider _modules_ are fully configurable.

**Builtin _sources_ are not activated (enabled) by default except for
_buffer_ and _path_ completion**.

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

#### Completion Provider Module Options

Following options are common to all completion sources.

Option|Type|Description
------|----|-----------
`enable`|`Boolean`|`true` to enable the source. Default is `false` for all builtin sources except _buffer_ and _path_ completion.
`maxCount`|`Number`|Number of completion items made available from the _source_. Default is `10`.
`priority`|`Number`|Higher priority items are shown at the top. Default is `10`.
`filetypes`|`List`|List of file-types to enable for a particular _source_. Default is `['*']` (all file-types), except for _dictionary_ _source_ which is set to `['text', 'markdown']`.

##### Buffer Module Options

_Buffer_ completion _module_ has additional options.

Option|Type|Description
------|----|-----------
`timeout`|`Number`|Maximum time spent searching for completion candidates in current buffer. Default is `100` milliseconds. If searching in multiple buffers additional 100 milliseconds is allocated. Search is aborted if any key is pressed.
`searchOtherBuffers`|`Boolean`|Search other listed buffers. Default is `true`.
`otherBuffersCount`|`Number`|Maximum number of other listed buffers to search. Default is `3`.
`icase`|`Boolean`|Ignore case when searching for completion candidates. Default is `true`.
`urlComplete`|`Boolean`|Complete http links in entirety. Useful when typing same url multiple times. Default is `false`.

##### Path Module Options

_Path_ completion _module_ options.

Option|Type|Description
------|----|-----------
`bufferRelativePath`|`Boolean`|Interpret relative paths as being relative to the directory of the current buffer. By default, paths are interpreted as relative to the current working directory (see `:pwd`). Default is `true`.

**Note**: Path completion kicks in when there is a `/` (`\` for Windows) or `.`
in the word before cursor. To autocomplete deeper in a directory type `/` at the end.

#### Enabling Options

Options are enabled using global function `g:VimCompleteOptionsSet()`. Here is
an example of how you can enable and configure completion sources.

```
vim9script
var options = {
    completor: { shuffleEqualPriority: true },
    buffer: { enable: true, priority: 10 },
    lsp: { enable: true, priority: 8 },
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

#### Enable and Disable

Autocompletion is enabled by default. You can enable or disable the plugin
anytime using commands.

```
:VimCompleteEnable
:VimCompleteDisable
```

You can selectively enable autocompletion for specified _file types_. For
example, enable autocompletion for `c`, `cpp`, `python`, `vim`, `text`, and
`markdown` files.

```
:VimCompleteEnable c cpp python vim text markdown
```

`VimCompleteEnable` takes space separated list of _file types_ as an argument. If
no argument is specified, then autocompletion is enabled for _all file types_. 

If you are using a plugin manager like
[vim-plug](https://github.com/junegunn/vim-plug) use the following in
$HOME/.vimrc.

```
autocmd VimEnter * VimCompleteEnable c cpp python vim text markdown
```

When Vim is started without any arguments it opens an unnamed buffer. This
buffer is not associated with any _file type_. To enable/disable autocompletion
on this buffer use the following variable. It is set by default.

```
g:vimcomplete_noname_buf_enable = true
```

#### List Completion Sources

Following command shows a list of completion sources enabled for the current
buffer.

```
:VimCompleteCompletors
```

## Demo

[![asciicast](https://asciinema.org/a/jNfngGm1FUxB0fkFryJxFBR3X.svg)](https://asciinema.org/a/jNfngGm1FUxB0fkFryJxFBR3X)

## Writing Your Own Extension

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

## Contributing

Pull requests are welcome.

## Similar Vim Plugins

- [asyncomplete](https://github.com/prabirshrestha/asyncomplete.vim)
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
