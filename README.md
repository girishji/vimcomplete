#### Async Autocompletion for Vim

A lightweight autocompletion plugin written entirely in Vim9
script.

## Features

- Code completion using [LSP](https://github.com/yegappan/lsp)
- Snippet completion using [vsnip](https://github.com/hrsh7th/vim-vsnip)
- Buffer word completion; Can search multiple buffers
- Dictionary (and next-word) completion using [ngrams](https://github.com/girishji/ngram-complete.vim)
- Dictionary completion using configured dictionary
- [Vimscript](https://github.com/girishji/vimscript-complete.vim) language completion (like LSP)
- Path completion
- Abbreviation completion (`:h abbreviations`)

Each of the above completion options can be configured for specific file types.

In addition, completion items can be sorted based on:

- Recency
- Length of item
- Priority
- Locality of item (for buffer completion)
- Exact case match

For cmdline-mode completion (`/`, `?`, and `:` commands) see [autosuggest](https://github.com/girishji/autosuggest.vim).

## Requirements

- Vim >= 9.0

## Installation

Install using [vim-plug](https://github.com/junegunn/vim-plug).
```
vim9script
plug#begin()
Plug 'girishji/ngram-complete.vim'
plug#end()
```

Alternately,
```
call plug#begin()
Plug 'girishji/ngram-complete.vim'
call plug#end()
```

Or use Vim's builtin package manager.
```
$ mkdir -p $HOME/.vim/pack/downloads/opt
$ cd $HOME/.vim/pack/downloads/opt
$ git clone https://github.com/girishji/vimcomplete.git
```

After installing the plugin using the above steps, add the following line to
your $HOME/.vimrc file:
```
packadd vimcomplete
```

## Configuration

This plugin is not enabled by default. Enable it by invoking the command
`VimCompleteEnable` in .vimrc. If you are using
[vim-plug](https://github.com/junegunn/vim-plug) enable through `VimEnter`
event as follows.
```
autocmd VimEnter * VimCompleteEnable
```

A better option is to enable the plugin selectively based on file type.
For example.,
```
autocmd FileType c,cpp,python,vim,text,markdown VimCompleteEnable
```

Autocompletion items are sourced from various provider modules. Some of the
lightweight modules are built-in (no additional plugin necessary). Some of
completion provider modules are kept external for ease of maintenance. These
plugins have to be installed separately. Following modules are built-in: LSP,
snippets, buffer, dictionary, path, and abbreviations. For LSP and snippets to
work [LSP client](https://github.com/yegappan/lsp) and
[snippet](https://github.com/hrsh7th/vim-vsnip) plugin have to be installed
separately.

Following provider modules are external to this plugin. See the links below for
installation and configuration instructions.

- Dictionary and next-word completion using [ngrams](https://github.com/girishji/ngram-complete.vim)
- [Vimscript language completion](https://github.com/girishji/vimscript-complete.vim) (like LSP)

Each provider module comes with separate set of options. In addition there are
options to configure completion engine itself. Each of these providers has to
be enabled, except for buffer, path and external modules which are enabled by default.

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

