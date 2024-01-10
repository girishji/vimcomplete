# Async Autocompletion Plugin for Vim

A lightweight async autocompletion plugin written in vim9script.

# Features

Words can be completed from the following sources.

- **[Buffer]()** words
- **[Dictionary]()** files
- **[LSP](https://github.com/yegappan/lsp)** client
- **[vsnip](https://github.com/hrsh7th/vim-vsnip)** client
- **[Ngrams](https://norvig.com/ngrams/)** database
- Vim's **[omnifunc]()**
- **[Path]()** search
- Vim's **[abbreviations]()**
- **[Vim9script]()** language (similar to LSP)

Each completion source above can be enabled and customized per 'file type' (`:h filetype`).

Additionally, completion items can be sorted according to the following criteria.

- Recency (using a LRU cache)
- Length of item
- Priority
- Proximity of item (for buffer completion)
- Case match

> [!NOTE]
> For cmdline-mode completion (`/`, `?`, and `:` commands), refer to **[autosuggest](https://github.com/girishji/autosuggest.vim)** plugin.


[![asciicast](https://asciinema.org/a/FMEp4BduAJdHtL48UpHL4JWbQ.svg)](https://asciinema.org/a/FMEp4BduAJdHtL48UpHL4JWbQ)


# Requirements

- Vim version 9.0 or higher

# Installation

Install it via [vim-plug](https://github.com/junegunn/vim-plug).

<details><summary><b>Show instructions</b></summary>

Using vim9 script:

```vim
vim9script
plug#begin()
Plug 'girishji/vimcomplete'
plug#end()
```

Using legacy script:

```vim
call plug#begin()
Plug 'girishji/vimcomplete'
call plug#end()
```

</details>

Install using Vim's built-in package manager.

<details><summary><b>Show instructions</b></summary>

```bash
$ mkdir -p $HOME/.vim/pack/downloads/opt
$ cd $HOME/.vim/pack/downloads/opt
$ git clone https://github.com/girishji/vimcomplete.git
```

Add the following line to your $HOME/.vimrc file (for builtin package manager only).

```vim
packadd vimcomplete
```

</details>

# Configuration

The completion sources mentioned above are not enabled by default except for
buffer words and path completion. This section shows how to configure completion
sources and the completion engine itself.

## Completion Engine

This entity obtains completion items from the configured completion sources
and displays the popup menu. Options that affect all sources and list displayed
in the popup menu are configured here.

Option|Type|Description
------|----|-----------
`sortByLength`|`Boolean`|Sort completion items by length. Default: `false`.
`recency`|`Boolean`|Display recently chosen items from the LRU cache. Items are shown at the top of the list. Default: `true`.
`recentItemCount`|`Number`|Count of recent items to show from LRU cache. Default: `5`.
`matchCase`|`Boolean`|Prioritize the items that match the case of the prefix being completed. Default: `true`.
`kindName`|`Boolean`|Show the completion 'kind' as a full word instead of a single letter. This option displays the name of source that provided the completion candidate. Default: `true`.
`shuffleEqualPriority`|`Boolean`|Arrange items from sources with equal priority so that the first item from each source appears at the top. Default: `false`.
`noNewlineInCompletion`|`Boolean`|If false, `<Enter>` ('<CR>') key in insert mode always inserts a newline. Otherwise, `<CR>` has default behavior (accept selected item and dismiss popup window without inserting newline). Default: `false`.
`alwaysOn`|`Boolean`| If `true` completion is triggered by `CTRL-N` and `CTRL-P` (see below to configure `<Tab>` and `<S-Tab>`). If `false` use `<C-Space>` (control-space) to trigger completion. Default is `true`.

## Buffer Words Completion

Current buffer (and other open buffers) are searched for completion candidates
using async mechanism with timeout. This ensures that large buffers do not bog
down completion engine.

Option|Type|Description
------|----|-----------
`enable`|`Boolean`|Set this to `false` to disable this source. Default: `true`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']` (all file types).
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.
`timeout`          | `Number`  | Maximum time allocated for searching completion candidates in the current buffer. Default: `100` milliseconds. If searching in multiple buffers, an additional 100 milliseconds is allocated. The search is aborted if any key is pressed.
`searchOtherBuffers`| `Boolean` | Determines whether to search other listed buffers. Default: `true`.
`otherBuffersCount`| `Number`  | Maximum number of other listed buffers to search. Default: `3`.
`icase`            | `Boolean` | Ignore case when searching for completion candidates. Default: `true`.
`urlComplete`      | `Boolean` | Enable completion of http links in entirety. Useful when typing the same URL multiple times. Default: `false`.
`envComplete`      | `Boolean` | Complete environment variables after typing the `$` character. Default: `false`.

## Dictionary Completion

Dictionary provider can search arbitrary list of words placed one per line in a
text file. The words may contain any non-space characters, and file need not be
sorted. This opens up a lot of possibilities. You can create a dictionary like
[pydiction](https://github.com/vim-scripts/Pydiction) and complete keywords,
functions, and methods for any programming language. Of course, it can also
search a sorted dictionary efficiently (binary search), like the dictionary of
English words that comes standard with linux distributions. Unsorted
dictionaries are searched in `O(n)` time but have acceptable performance below
3MB file size (depending on your system of course).

Dictionary files can have comments. Lines starting with `---` are treated as
comments and ignored.

Option|Type|Description
------|----|-----------
`enable`|`Boolean`|Set this to `true` to enable this source. Default: `false`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['text', 'markdown']`.
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.
`sortedDict`       | `Boolean` | `true` if the dictionary file is sorted, `false` otherwise. This option affects both performance and correctness. Take care to set it correctly. Default: `true`.
`onlyWords`| `Boolean` | Set this to `true` if dictionary contains only alphanumeric words. If dictionary contains characters like `@`, `.`, `(`, etc. set this to `false`. Default: `true`.
`matcher`| `String` | This option is active only when `onlyWords` is set to `true`. Accepted values are 'case' (case sensitive), 'ignorecase', and 'smartcase' (case sensitive in the presence of upper case letters, otherwise like `ignorecase`).

<details><summary><b>Show sample configuration</b></summary>

There is more information about setting up configuration later on. However, a
sample configuration specific to dictionary source is provided here.

Dictionary files can be configured for each 'filetype' (`:h filetype`). In the
following sample, dictionary module is enabled for
filetypes 'python' and 'text'. Vim option `dictionaries` is set appropriately.
Dictionary specific options are set for each filetype.

```
vim9script
var dictproperties = {
    python: { onlyWords: false, sortedDict: false},
    text: { onlyWords: true, sortedDict: true, matcher: 'ignorecase' }
}
var vcoptions = {
    dictionary: { enable: true, priority: 11, filetypes: ['python', 'text'], properties: dictproperties },
}
autocmd VimEnter * g:VimCompleteOptionsSet(vcoptions)
autocmd FileType text set dictionary+=/usr/share/dict/words
autocmd FileType python set dictionary=$HOME/.vim/data/pythondict
```

</details>/

> [!TIP]
> For completing English words use [ngram]() completion (below) or use custom dictionary with frequently used words. The builtin dictionary that comes with Linux or MacOS contains many rarely used words.

## LSP Completion

This source obtains autocompletion items from the
[LSP client](https://github.com/yegappan/lsp).

> [!IMPORTANT]
> Please install the [LSP client](https://github.com/yegappan/lsp) separately.

Option|Type|Description
------|----|-----------
`enable`|`Boolean`|Set this to `true` to enable this source. Default: `false`.
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.
`keywordOnly`|`Boolean`|If `true` completion will be triggered after any keyword character (`:h 'iskeyword'`). `false` will trigger completion after non-keywords like `.`. Default: `false`.
`filetypes`|`List`|This option need not be specified. If this option is not specified or is empty, completion items are sourced for any file type for which LSP is configured. Otherwise, items are sourced only for listed file types. Default: Not specified.

## Vsnip Completion

This source provides snippet completion from [vim-vsnip](https://github.com/hrsh7th/vim-vsnip).

> [!IMPORTANT]
> Please install the following separately.
> - [vim-vsnip](https://github.com/hrsh7th/vim-vsnip)
> - [vim-vsnip-integ](https://github.com/hrsh7th/vim-vsnip-integ)
> Optional:
> - [friendly-snippets](https://github.com/rafamadriz/friendly-snippets)

> [!NOTE]
> `<Tab>` key can be used to hop within a snippet. Popup completion menu will not open when snippet is active. However, the last stop within the snippet will activate the popup window. If you want to hop back within the snippet using `<S-Tab>` simply dismiss the popup using `CTRL-E`.

Option|Type|Description
------|----|-----------
`enable`|`Boolean`|Set this to `true` to enable this source. Default: `false`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']` (all file types).
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.
`adaptNonKeyword`|`Boolean`|(experimental) When completing snippets starting with non-keywords, say '#i' for instance, adjust completion such that they are compatible with items starting with keywords like 'i' (returned by LSP, for instance). Default is `false`.

## Ngrams Completion

This source is kept as a separate plugin since it includes large database
files. Please see
**[ngram-complete](https://github.com/girishji/ngram-complete.vim)** for
installation and usage instructions.

## Omnifunc Completion

This source completes items emitted by the function set in `omnifunc` (`:h 'omnifunc'`) Vim variable.

Vim provides language based autocompletion through Omni completion for many
languages (see `$VIMRUNTIME/autoload`). This is a lightweight alternative to using LSP.

| __Vim File__  | __Language__  |
|---|---|
|ccomplete.vim|C|
|csscomplete.vim|HTML / CSS|
|htmlcomplete.vim|HTML|
|javascriptcomplete.vim|Javascript|
|phpcomplete.vim|PHP|
|pythoncomplete.vim|Python|
|rubycomplete.vim|Ruby|
|syntaxcomplete.vim|from syntax highlighting|
|xmlcomplete.vim|XML (uses files in the xml directory)|

Vim sets the `omnifunc` option automatically when file type is detected.

Also, any user defined `omnifunc` can also be used for autocompletion.

> [!CAUTION]
> Disable the [LSP Completion]() when using this source.

Option|Type|Description
------|----|-----------
`enable`|`Boolean`|Set this to `true` to enable this source. Default: `false`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['python', 'javascript']`.
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.

## Path Completion

Both relative and absolute path names are completed.

| Option              | Type      | Description                                                                                   |
|---------------------|-----------|-----------------------------------------------------------------------------------------------|
| `enable`|`Boolean`|Set this to `false` to disable this source. Default: `true`. |
| `filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']` (all file types). |
| `maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`. |
| `priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `12`. |
| `bufferRelativePath`| `Boolean` | Interpret relative paths relative to the directory of the current buffer. Default: `true`.    |

> [!NOTE]
> Path completion activates when there is a `/` (`\` for Windows) or `.` in the word before the cursor. To autocomplete deeper in a directory, type `/` at the end.

## Abbreviations Completion

Abbreviations (`:h abbreviations`) are completed based on the `id`.

| Option              | Type      | Description                                                                                   |
|---------------------|-----------|-----------------------------------------------------------------------------------------------|
| `enable`|`Boolean`|Set this to `true` to enable this source. Default: `false`. |
| `filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']` (all file types). |
| `maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`. |
| `priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`. |

## Vim9script Language Completion

This source completes Vim9 script function names, arguments, variables, reserved words and
the like. If you are developing a Vim plugin or configuring a non-trivial _.vimrc_ this
can be useful.

<details><summary><b>Show demo</b></summary>

[![asciicast](https://asciinema.org/a/FMEp4BduAJdHtL48UpHL4JWbQ.svg)](https://asciinema.org/a/FMEp4BduAJdHtL48UpHL4JWbQ)

[![asciicast](https://asciinema.org/a/lggBAwfS2Zg7RpCccfTRem0pb.svg)](https://asciinema.org/a/lggBAwfS2Zg7RpCccfTRem0pb)

</details>

| Option              | Type      | Description                                                                                   |
|---------------------|-----------|-----------------------------------------------------------------------------------------------|
| `enable`|`Boolean`|Set this to `false` to disable this source. Default: `true`. |
| `filetypes`|`List`|List of file types for which this source is enabled. Default: `['vim']`. |
| `maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`. |
| `priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`. |


## Configure Options

Options are configured using the global function `g:VimCompleteOptionsSet()`.
Below example shows how to enable and configure completion sources. Not all
options are demonstrated here; please refer to the tables above for all
available options.

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

You can map `<Tab>` and `<S-Tab>` keys to select autocompletion items. By default, `CTRL-N` and `CTRL-P` select the menu items.

```vim
vim9script
g:vimcomplete_tab_enable = 1
```

> [!NOTE]
> For help with other keybindings see `:h popupmenu-keys`. It includes keybindings for `<BS>`, `CTRL-H`, `CTRL-L`, `CTRL-Y`, `CTRL-E`, `<PageUp>`, `<PageDown>`, `<Up>`, and `<Down>` keys when popup menu is open.

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

# Writing Your Own Extension

Start by examining the implementation of an external plugin like [ngrams-viewer](https://github.com/girishji/ngramview-complete.vim) (which spawns a new process to handle http requests) or [ngram-complete](https://github.com/girishji/ngram-complete.vim).

The completion engine employs an interface similar to Vim's [complete-functions](https://vimhelp.org/insert.txt.html#complete-functions). However, the function is invoked in three ways instead of two:

- First, to find the start of the text to be completed.
- Next, to check if completion candidates are available.
- Lastly, to find the actual matches.

The first and last invocation are identical to Vim's [complete-functions](https://vimhelp.org/insert.txt.html#complete-functions). During the second invocation, the arguments are:

- `findstart: 2`
- `base: empty`

The function must return `true` or `false` to indicate whether completion candidates are ready. Only when this return value is `true` will the function be invoked for the third time to get the actual matches. This step is essential for asynchronous completion.

The name of the completion function does not matter, but it should take two arguments: `findstart: Number` and `base: String`, and return `<any>`. Register this function with the completion engine by calling `vimcompletor.Register()`. Use the `User` event of type `VimCompleteLoaded` to time the registration.

When users set options through the configuration file, a `User` event with type `VimCompleteOptionsChanged` is issued. The plugin should register for this event and update its internal state accordingly.

# Contributing

Pull requests are welcomed.

## Similar Vim Plugins

- [asyncomplete](https://github.com/prabirshrestha/asyncomplete.vim)
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

