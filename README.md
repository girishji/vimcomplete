# VimComplete

Async autocompletion plugin for Vim, written in vim9script.


<p>
  <a href="#key-features">Key Features</a> •
  <a href="#requirements">Requirements</a> •
  <a href="#installation">Installation</a> •
  <a href="#configuration">Configuration</a>
</p>


![Screenshot](img/demo.gif)


## Key Features

Words can be completed from various sources:

- **Buffer** words
- **Dictionary** files
- **[LSP](https://github.com/yegappan/lsp)** client
- **Snippets** ([vim-vsnip](https://github.com/hrsh7th/vim-vsnip) client)
- **[Ngrams](https://norvig.com/ngrams/)** database
- Vim's **omnifunc**
- **Path** search
- Vim's **abbreviations**
- **Vim9script** language (similar to LSP)

Each completion source above can be enabled and customized per 'file type' (`:h filetype`).

Completion items are sorted according to the following criteria:

- Recency (using a LRU cache)
- Length of item
- Priority
- Proximity of item (for buffer completion)
- Case match

> [!NOTE]
> For cmdline-mode completion (`/`, `?`, and `:` commands), refer to **[autosuggest](https://github.com/girishji/autosuggest.vim)** plugin.


## Requirements

- Vim version 9.0 or higher

## Installation

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

## Configuration

The completion sources mentioned above, aside from buffer words and path completion, are not enabled by default. This section provides instructions on configuring both the completion sources and the completion engine itself.

### Completion Engine

This entity retrieves completion items from the enabled completion sources and then displays the popup menu.

Option|Type|Description
------|----|-----------
`sortByLength`|`Boolean`|Sort completion items by length. Default: `false`.
`recency`|`Boolean`|Display recently chosen items from the LRU cache. Items are shown at the top of the list. Default: `true`.
`recentItemCount`|`Number`|Count of recent items to show from LRU cache. Default: `5`.
`matchCase`|`Boolean`|Prioritize the items that match the case of the prefix being completed. Default: `true`.
`kindName`|`Boolean`|Show the completion 'kind' as a full word instead of a single letter. This option displays the name of source that provided the completion candidate. Default: `true`.
`shuffleEqualPriority`|`Boolean`|Arrange items from sources with equal priority such that the first item of all sources appear before the second item of any source. Default: `false`.
`noNewlineInCompletion`|`Boolean`|If false, `<Enter>` ('<CR>') key in insert mode always inserts a newline. Otherwise, `<CR>` has default behavior (which is to accept selected item and dismiss popup window without inserting newline). Default: `false`.
`alwaysOn`|`Boolean`| If set to `true`, the completion menu is automatically triggered by any change in the buffer. If set to `false`, use `<C-Space>` (control-space) to manually trigger auto-completion. Default: true.

### Buffer Completion

The current buffer, as well as other open buffers, are searched for completion candidates using an asynchronous mechanism with a timeout. This approach ensures that the completion engine is not slowed down by large buffers.

Option|Type|Description
------|----|-----------
`enable`|`Boolean`|Set this to `false` to disable buffer completion. Default: `true`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']` (all file types).
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.
`timeout`          | `Number`  | Maximum time allocated for searching completion candidates in the current buffer. Default: `100` milliseconds. If searching in multiple buffers, an additional 100 milliseconds is allocated. The search is aborted if any key is pressed.
`searchOtherBuffers`| `Boolean` | Determines whether to search other listed buffers. Default: `true`.
`otherBuffersCount`| `Number`  | Maximum number of other listed buffers to search. Default: `3`.
`icase`            | `Boolean` | Ignore case when searching for completion candidates. Default: `true`.
`urlComplete`      | `Boolean` | Enable completion of http links in entirety. This is useful when typing the same URL multiple times. Default: `false`.
`envComplete`      | `Boolean` | Complete environment variables after typing the `$` character. Default: `false`.

### Dictionary Completion

The dictionary provider is capable of searching an arbitrary list of words placed one per line in a text file. These words can encompass any non-space characters, and the file doesn't necessarily need to be sorted. This feature presents various opportunities. For instance, you can create a dictionary akin to [Pydiction](https://github.com/vim-scripts/Pydiction), enabling the completion of keywords, functions, and method names for any programming language. Moreover, it can efficiently search a sorted dictionary using binary search.

Unsorted dictionaries are searched in linear time `O(n)`, but they tend to perform acceptably well for file sizes below 3MB (performance might vary depending on your system).

Additionally, the dictionary files can include comments. Lines beginning with `---` are treated as comments and are disregarded during the search process.


Option|Type|Description
------|----|-----------
`enable`|`Boolean`|Set this to `true` to enable dictionary completion. Default: `false`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['text', 'markdown']`.
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.
`sortedDict`       | `Boolean` | `true` if the dictionary file is sorted, `false` otherwise. This option affects both performance and correctness. Take care to set it correctly. Default: `true`.
`onlyWords`| `Boolean` | Set this to `true` if dictionary contains only alphanumeric words. If dictionary contains characters like `@`, `.`, `(`, etc. set this option to `false`. Default: `true`.
`matcher`| `String` | This option is active only when `onlyWords` is set to `true`. Accepted values are 'case' (case sensitive), 'ignorecase', and 'smartcase' (case sensitive in the presence of upper case letters, otherwise ignores case).

<details><summary><b>Show sample configuration</b></summary>

Further information about setting up configurations will be available later. Nonetheless, here is a sample configuration specifically targeting the dictionary source.

Dictionary files can be configured individually for each 'filetype' (`:h filetype`). In the provided sample, the dictionary module is enabled for filetypes 'python' and 'text'. The Vim option `dictionaries` is appropriately set. Moreover, specific dictionary options are defined for each respective filetype.

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

</details>

> [!TIP]
> For completing English words, you can utilize [ngram](https://en.wikipedia.org/wiki/N-gram) completion as outlined below, or opt for a custom dictionary containing frequently used words. The default dictionary that comes pre-installed with Linux or MacOS encompasses numerous infrequently used words.

### LSP Completion

This source obtains autocompletion items from the
[LSP client](https://github.com/yegappan/lsp).

> [!IMPORTANT]
> Please install the [LSP client](https://github.com/yegappan/lsp) separately.

Option|Type|Description
------|----|-----------
`enable`|`Boolean`|Set this to `true` to enable LSP completion. Default: `false`.
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.
`keywordOnly`|`Boolean`|If `true` completion will be triggered after any keyword character as defined by the file type (`:h 'iskeyword'`). `false` will trigger completion after non-keywords like `.` (for instance). Default: `false`.
`filetypes`|`List`|This option need not be specified. If this option is not specified or is empty, completion items are sourced for any file type for which LSP is configured. Otherwise, items are sourced only for listed file types. Default: Not specified.

### Vsnip Completion

This source provides snippet completion from [vim-vsnip](https://github.com/hrsh7th/vim-vsnip).

> [!IMPORTANT]
> Please install the following separately.
> - [vim-vsnip](https://github.com/hrsh7th/vim-vsnip)
> - [vim-vsnip-integ](https://github.com/hrsh7th/vim-vsnip-integ)
> Optional:
> - [friendly-snippets](https://github.com/rafamadriz/friendly-snippets)


Option|Type|Description
------|----|-----------
`enable`|`Boolean`|Set this to `true` to enable this source. Default: `false`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']` (all file types).
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.
`adaptNonKeyword`|`Boolean`|(experimental) When completing snippets starting with non-keywords, say '#i' for instance, adjust completion such that they are compatible with items starting with keywords like 'i' (returned by LSP, for instance). Default is `false`.

> [!NOTE]
> The `<Tab>` key facilitates movement within a snippet. When a snippet is active, the popup completion menu won't open. However, the popup window will activate upon reaching the final stop within the snippet. If you wish to navigate backward within the snippet using `<S-Tab>`, you can dismiss the popup by using `CTRL-E`.


### Ngrams Completion

This source is kept as a separate plugin since it includes large database
files. Please see
**[ngram-complete](https://github.com/girishji/ngram-complete.vim)** for
installation and usage instructions.

### Omnifunc Completion

This source completes items emitted by the function set in `omnifunc` (`:h 'omnifunc'`).

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
> Disable the [LSP Completion]() when using omnifunc.

Option|Type|Description
------|----|-----------
`enable`|`Boolean`|Set this to `true` to enable omnifunc completion. Default: `false`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['python', 'javascript']`.
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.

### Path Completion

Both relative and absolute path names are completed.

| Option              | Type      | Description                                                                                   |
|---------------------|-----------|-----------------------------------------------------------------------------------------------|
| `enable`|`Boolean`|Set this to `false` to disable path completion. Default: `true`. |
| `filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']` (all file types). |
| `maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`. |
| `priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `12`. |
| `bufferRelativePath`| `Boolean` | Interpret relative paths relative to the directory of the current buffer. Otherwise paths are interpreted relative to the dicrectory from which Vim is started. Default: `true`.    |

> [!NOTE]
> Path completion activates when there is a `/` (`\` for Windows) or `.` in the word before the cursor. To autocomplete deeper in a directory type `/` at the end.

### Abbreviations Completion

Abbreviations (`:h abbreviations`) are completed based on the `id`.

| Option              | Type      | Description                                                                                   |
|---------------------|-----------|-----------------------------------------------------------------------------------------------|
| `enable`|`Boolean`|Set this to `true` to enable abbreviation completion. Default: `false`. |
| `filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']` (all file types). |
| `maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`. |
| `priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`. |

### Vim9script Language Completion

This source completes Vim9 script function names, arguments, variables, reserved words and
the like. Enable this if you are developing a Vim plugin or configuring a non-trivial _.vimrc_.


| Option              | Type      | Description                                                                                   |
|---------------------|-----------|-----------------------------------------------------------------------------------------------|
| `enable`|`Boolean`|Set this to `false` to disable this source. Default: `true`. |
| `filetypes`|`List`|List of file types for which this source is enabled. Default: `['vim']`. |
| `maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`. |
| `priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`. |


### Configure Options

Options can be configured using the global function `g:VimCompleteOptionsSet()`. The example below illustrates how to enable and configure completion sources. Please note that not all options are demonstrated here; for a comprehensive list of all available options, refer to the tables provided above.

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

### Tab Completion

You can map `<Tab>` and `<S-Tab>` keys to select autocompletion items. By default, `CTRL-N` and `CTRL-P` select the menu items.

```vim
vim9script
g:vimcomplete_tab_enable = 1
```

> [!NOTE]
> For help with other keybindings see `:h popupmenu-keys`. This help section includes keybindings for `<BS>`, `CTRL-H`, `CTRL-L`, `CTRL-Y`, `CTRL-E`, `<PageUp>`, `<PageDown>`, `<Up>`, and `<Down>` keys when popup menu is open.

### Enabling and Disabling

Autocompletion is enabled by default. At any time, you can enable or disable the plugin using the following commands:

```vim
:VimCompleteEnable
:VimCompleteDisable
```

You can selectively enable autocompletion for specific _file types_. For instance, enable autocompletion for `c`, `cpp`, `python`, `vim`, `text`, and `markdown` files.

```vim
:VimCompleteEnable c cpp python vim text markdown
```

`VimCompleteEnable` takes a space-separated list of _file types_ as an argument. If no argument is specified, autocompletion is enabled for _all file types_.

When Vim opens an unnamed buffer, it is not associated with any _file type_. To enable or disable autocompletion on the unnamed buffer, set the following variable (set by default).

```vim
vim9script
g:vimcomplete_noname_buf_enable = true
```

### Listing Completion Sources

The following command displays a list of completion sources enabled for the current buffer.

```vim
:VimCompleteCompletors
```

## Writing Your Own Extension

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

## Contributing

Pull requests are welcomed.

## Similar Vim Plugins

- [asyncomplete](https://github.com/prabirshrestha/asyncomplete.vim)
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

