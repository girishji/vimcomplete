#### Async Autocompletion for Vim

A lightweight autocompletion plugin written entirely in Vim9
script.

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

For cmdline-mode completion (`/`, `?`, and `:`) see [autosuggest](https://github.com/girishji/autosuggest.vim) plugin.

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

This plugin is not enabled by default. Enable it by invoking the command
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

Autocompletion items are sourced from various provider _modules_. Some _modules_
are internal (builtin) to this plugin (no additional plugins necessary). Some of
the _modules_ are kept external for ease of maintenance. These
plugins have to be installed separately. Following _modules_ are built-in: _LSP_,
_snippets_, _buffer_, _dictionary_, _path_, and _abbreviations_. _LSP_ and
_snippets_ modules
need additional plugins. Install [LSP client](https://github.com/yegappan/lsp)
and [vim-vsnip](https://github.com/hrsh7th/vim-vsnip).

Following _modules_ are external to this plugin. See the links below for
installation and configuration instructions.

- Dictionary and next-word completion using [_ngrams_](https://github.com/girishji/ngram-complete.vim) (recommended)
- [_Vimscript_ language completion](https://github.com/girishji/vimscript-complete.vim) (like LSP)

Both completion _engine_ and completion _modules_ are fully configurable.
Completion _modules_ are *not* enabled by default except for _buffer_ word completion
and _path_ completion modules.

#### Completion Engine Options

Option|Type|Description
------|----|-----------
`sortByLength`|`bool`|Sort completion items based on length. Default is `false`.
`recency`|`bool`|Show most recently chosen items at the top (based on LRU cache). Default is `true`.
`recentItemCount`|`number`|Number of recent items to show at the top. Default is `5`.
`matchCase`|`bool`|Some provider modules return items that may not match the case of prefix being completed. Show items that match case with prefix at the top followed by other items. Default is `true`.
`kindName`|`bool`|Show the kind of completion as a full word (verbose) instead of a single letter. Default set to `true`.
`shuffleEqualPriorityItems`|`bool`|Shuffle items of equal priority. Default set to `false`.
`noNewlineInCompletion`|`bool`|<Enter> key in insert mode stops completion and inserts an <Enter>. Default set to `false`.

#### Completion Provider Module Options

Following options are common to all completion provider modules.

Option|Type|Description
------|----|-----------
`enable`|`bool`|`true` to enable the module. Default is `false` for all built-in modules except 'buffer'.
`maxCount`|`number`|Number of completion items made available from the module. Default is `10`.
`priority`|`number`|Higher priority items are shown at the top. Default is `10`.
`filetypes`|`list<string>`|List of file-types to enable this provider. Default is `['*']` (all file-types), except for 'dictionary' which is set to `['text', 'markdown']`.

Buffer module has some additional options.

Option|Type|Description
------|----|-----------
`timeout`|`number`|Maximum time spent searching for completion candidates in current buffer. Default is `100` milliseconds. If searching in multiple buffers additional 100 milliseconds is allocated. Non-blocking search--search is aborted if a key is pressed.
`searchOtherBuffers`|`bool`|Search other listed buffers. Default is `true`.
`otherBuffersCount`|`number`|Maximum number of other listed buffers to search. Default is `3`.
`icase`|`bool`|Ignore case when searching for completion candidates. Default is `true`.
`urlComplete`|`bool`|Complete http links in entirety. Helps when typing same url multiple times. Default is `false`.

Options are enabled using global function `g:VimCompleteOptionsSet()`. Here is
an example of how you can enable and configure completion modules.

```
vim9script
var options = {
    completor: { shuffleEqualPriorityItems: true },
    buffer: { enable: true, priority: 10 },
    abbrev: { enable: true, priority: 8 },
    lsp: { enable: true, priority: 9 },
    vsnip: { enable: true, priority: 9 },
    ngram: {
        enable: true,
        priority: 10,
        bigram: false,
        filetypes: ['text', 'help', 'markdown'],
        filetypesComments: ['c', 'cpp', 'python', 'java', 'lua', 'vim', 'zsh', 'r'],
    },
}
autocmd VimEnter * g:VimCompleteOptionsSet(options)
```

#### Tab Completion

<C-N> and <C-P> select the menu items. However, <Tab> and <Shift-Tab> keys can
be mapped to provide more intuitive experience.

```
g:vimcomplete_tab_enable = 1
```

#### Commands 

To enable and disable plugin,

```
:VimCompleteEnable
:VimCompleteDisable
```

To view which completion modules are enabled for a file,

```
:VimCompleteCompletors
```

## Writing Your Own Completion Module

A good place to start is by looking through the implementation of external
plugins [Vimscript
completion](https://github.com/girishji/vimscript-complete.vim),
[ngrams](https://github.com/girishji/ngram-complete.vim), and
[ngrams-viewer](https://github.com/girishji/ngramview-complete.vim) which
spawns a new process to handle http requests.

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

It does not matter what the name of the completion provider function is but it
should take two arguments `findstart: number` and `base: string` and return
`<any>`. This function should be registered with completion engine by calling
`vimcompletor.Register()` function. The `User` event of type
`VimCompleteLoaded` can be used to time the registration.

When the user configures options a `User` event with type
`VimCompleteOptionsChanged` is issued. The plugin should register for this
event and update its internal state appropriately.

