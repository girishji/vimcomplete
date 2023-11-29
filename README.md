# Async Autocompletion Plugin for Vim

A lightweight async autocompletion plugin written in vim9script.

# Features

- [LSP](https://github.com/yegappan/lsp)-powered [code completion](https://github.com/girishji/lsp-complete.vim)
- [vsnip](https://github.com/hrsh7th/vim-vsnip)-driven [snippet completion](https://github.com/girishji/vsnip-complete.vim)
- Buffer word completion that does not hang on large buffers
- Vim's [omnifunc](https://github.com/girishji/omnifunc-complete.vim) language completion
- Dictionary completion support
- Ngrams-based dictionary (and next-word) completion via [ngrams](https://github.com/girishji/ngram-complete.vim)
- [Vimscript](https://github.com/girishji/vimscript-complete.vim) language completion (similar to LSP)
- Path completion functionality
- Abbreviation completion

Each completion option above is customizable per file type.

Additionally, completion items can be sorted by:

- Recency
- Length of item
- Priority
- Locality of item (for buffer completion)
- Case match

For cmdline-mode completion (`/`, `?`, and `:`), refer to the **[autosuggest](https://github.com/girishji/autosuggest.vim)** plugin.

# Requirements

- Vim version 9.0 or higher

# Installation

Install it via [vim-plug](https://github.com/junegunn/vim-plug):

```vim
vim9script
plug#begin()
Plug 'girishji/vimcomplete'
plug#end()
```

Alternatively, for Vim's built-in package manager:

```bash
$ mkdir -p $HOME/.vim/pack/downloads/opt
$ cd $HOME/.vim/pack/downloads/opt
$ git clone https://github.com/girishji/vimcomplete.git
```

For the built-in package manager, add this line to your $HOME/.vimrc file:

```vim
packadd vimcomplete
```

# Configuration

Autocompletion items are sourced both internally and externally through _modules_.
Internal _sources_ include _buffer_, _dictionary_, _path_, and _abbrev_.

External to this plugin, the following _sources_ exist. See the links below for
installation and configuration instructions:

- _LSP_ based [code completion](https://github.com/girishji/lsp-complete.vim)
- Vim's _omnifunc_ based [code completion](https://github.com/girishji/omnifunc-complete.vim)
- Dictionary and next-word completion using [_ngram_](https://github.com/girishji/ngram-complete.vim)
- _vimscript_ [language completion](https://github.com/girishji/vimscript-complete.vim) (akin to LSP)
- _vsnip_ [snippet completion](https://github.com/girishji/vsnip-complete.vim)

Both the completion _engine_ and source provider _modules_ are fully configurable.

**Note**: Builtin _sources_ are not activated (enabled) by default except for
_buffer_ and _path_ completion.

## Completion Engine Options

Option|Type|Description
------|----|-----------
`sortByLength`|`Boolean`|Sort completion items by the length of autocompletion text. Default: `false`.
`recency`|`Boolean`|Display recently chosen items at the top. Default: `true`.
`recentItemCount`|`Number`|Count of recent items to show at the top. Default: `5`.
`matchCase`|`Boolean`|Show items that match the case of the prefix being completed at the top. Default: `true`.
`kindName`|`Boolean`|Show the completion kind as a full word instead of a single letter. Default: `true`.
`shuffleEqualPriority`|`Boolean`|Arrange items from sources with equal priority so that the first item from each source appears at the top. Default: `false`.
`noNewlineInCompletion`|`Boolean`|In insert mode, pressing `<Enter>` stops completion and inserts an `<Enter>`. Default: `false`.
`alwaysOn`|`Boolean`| If `false` use `<c-space>` (control-space) to trigger completion. Default is `true`.

## Completion Provider Module General Options

The following options apply universally to all completion sources.

Option|Type|Description
------|----|-----------
`enable`|`Boolean`|Set to `true` to enable the source. Default: `false` for all builtin sources except for _buffer_ and _path_ completion.
`maxCount`|`Number`|Count of available completion items from the source. Default: `10`.
`priority`|`Number`|Higher priority items are displayed at the top. Default: `10`.
`filetypes`|`List`|List of file types to enable for a specific source. Default: `['*']` (all file types) except for _dictionary_ source, which is set to `['text', 'markdown']`.

## Buffer Module Options

In addition to the options mentioned above, the _Buffer_ completion _module_ has its specific configurations.

| Option             | Type      | Description                                                                                       |
|--------------------|-----------|---------------------------------------------------------------------------------------------------|
| `timeout`          | `Number`  | Maximum time allocated for searching completion candidates in the current buffer. Default: `100` milliseconds. If searching in multiple buffers, an additional 100 milliseconds is allocated. The search is aborted if any key is pressed. |
| `searchOtherBuffers`| `Boolean` | Determines whether to search other listed buffers. Default: `true`.                                |
| `otherBuffersCount`| `Number`  | Maximum number of other listed buffers to search. Default: `3`.                                     |
| `icase`            | `Boolean` | Ignore case when searching for completion candidates. Default: `true`.                               |
| `urlComplete`      | `Boolean` | Enable complete http links in entirety. Useful when typing the same URL multiple times. Default: `false`. |
| `envComplete`      | `Boolean` | Complete environment variables after `$`. Default: `false`.                                         |

## Path Module Options

In addition to the general options mentioned above, the _Path_ completion _module_ has its specific configurations.

| Option              | Type      | Description                                                                                   |
|---------------------|-----------|-----------------------------------------------------------------------------------------------|
| `bufferRelativePath`| `Boolean` | Interpret relative paths relative to the directory of the current buffer. Default: `true`.     |

**Note**: Path completion activates when there is a `/` (`\` for Windows) or `.` in the word before the cursor. To autocomplete deeper in a directory, type `/` at the end.

## Configure Options

Options are configured using the global function `g:VimCompleteOptionsSet()`. Below is an example showcasing how to enable and configure completion sources. Not all options are demonstrated here; please refer to the tables above for all available options.

```vim
vim9script
var options = {
    completor: { shuffleEqualPriority: true },
    buffer: { enable: true, priority: 10, urlComplete: true, envComplete: true },
    abbrev: { enable: true, priority: 10 },
    lsp: { enable: true, priority: 10, maxCount: 5 },
    omnifunc: { enable: false, priority: 8, filetypes: ['python', 'javascript'] },
    vsnip: { enable: true, priority: 11 },
    vimscript: { enable: true, priority: 11 },
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

# Tab Completion

You can map `<Tab>` and `<S-Tab>` keys to select autocompletion items. By default, `<C-N>` and `<C-P>` select the menu items.

```vim
vim9script
g:vimcomplete_tab_enable = 1
```

# Enabling and Disabling

Autocompletion is enabled by default. You can enable or disable the plugin anytime using commands.

```vim
:VimCompleteEnable
:VimCompleteDisable
```

You can selectively enable autocompletion for specific _file types_. For instance, enable autocompletion for `c`, `cpp`, `python`, `vim`, `text`, and `markdown` files.

```vim
:VimCompleteEnable c cpp python vim text markdown
```

`VimCompleteEnable` takes a space-separated list of _file types_ as an argument. If no argument is specified, autocompletion is enabled for _all file types_.

When Vim opens an unnamed buffer without any arguments, this buffer is not associated with any _file type_. To enable or disable autocompletion on this buffer, use the following variable (set by default).

```vim
vim9script
g:vimcomplete_noname_buf_enable = true
```

# Listing Completion Sources

The following command displays a list of completion sources enabled for the current buffer.

```vim
:VimCompleteCompletors
```

# Demo

[![asciicast](https://asciinema.org/a/jNfngGm1FUxB0fkFryJxFBR3X.svg)](https://asciinema.org/a/jNfngGm1FUxB0fkFryJxFBR3X)

# Writing Your Own Extension

Start by examining the implementation of external plugins like [Vimscript](https://github.com/girishji/vimscript-complete.vim) completion, [ngrams](https://github.com/girishji/ngram-complete.vim), and [ngrams-viewer](https://github.com/girishji/ngramview-complete.vim) (which spawns a new process to handle http requests).

The Completion engine employs an interface similar to Vim's [complete-functions](https://vimhelp.org/insert.txt.html#complete-functions). However, the function is invoked in three ways instead of two:

- First, to find the start of the text to be completed.
- Next, to check if completion candidates are available.
- Lastly, to find the actual matches.

The first and last invocation are identical to Vim's [complete-functions](https://vimhelp.org/insert.txt.html#complete-functions). During the second invocation, the arguments are:

- `findstart: 2`
- `base: empty`

The function must

 return `true` or `false` to indicate whether completion candidates are ready. Only when this return value is `true` will the function be invoked for the third time to get the actual matches. This step is essential for asynchronous completion.

The name of the completion function does not matter, but it should take two arguments: `findstart: Number` and `base: String`, and return `<any>`. Register this function with the completion engine by calling `vimcompletor.Register()`. Use the `User` event of type `VimCompleteLoaded` to time the registration.

When users set options through the configuration file, a `User` event with type `VimCompleteOptionsChanged` is issued. The plugin should register for this event and update its internal state accordingly.

# Contributing

Pull requests are welcomed.

## Similar Vim Plugins

- [asyncomplete](https://github.com/prabirshrestha/asyncomplete.vim)
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)



