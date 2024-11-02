
<h1 align="center"> VimComplete </h1>

<h4 align="center"> A lightweight autocompletion plugin for Vim, written in vim9script. </h4>

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#requirements">Requirements</a> •
  <a href="#installation">Installation</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#commands">Commands</a> •
  <a href="#Writing-Your-Own-Extension">Add-on</a>
</p>

![Demo](https://gist.githubusercontent.com/girishji/40e35cd669626212a9691140de4bd6e7/raw/6041405e45072a7fbc4e352cbd461e450a7af90e/vimcomplete-demo.gif)


# Key Features

Words are sourced ***asynchronously*** from various sources:

- **[Buffers](#buffer-Completion)**
- **[Dictionary](#dictionary-Completion)** files
- **[Code](#lsp-Completion)** completion sourced from [LSP](https://github.com/yegappan/lsp) client
- **[Snippets](#snippets-Completion)** from [vim-vsnip](https://github.com/hrsh7th/vim-vsnip) client
- **[Words and bigrams](#ngrams-Completion)** from [Ngrams](https://norvig.com/ngrams/) database
- Vim's **[omnifunc](#omnifunc-Completion)**
- **[Path](#path-Completion)** search
- Vim's **[abbreviations](#abbreviations-Completion)**
- **[Vim9script](#vim9script-language-Completion)** language (similar to LSP)
- **[Tmux](#tmux-Completion)** panes
- **[Tag](#tag-Completion)** names

All crucial source modules are integrated, eliminating the need to manage
multiple plugins. Users have the flexibility to enable or disable each
completion source and customize settings on a per-file-type basis (`:h filetype`).


Completion items are _sorted_ according to the following criteria:

- Recency (using a LRU cache)
- Length of item
- Priority
- Proximity of item (for buffer completion)
- Case match

> [!NOTE]
> For cmdline-mode completion (`/`, `?`, and `:` commands), refer to **[VimSuggest](https://github.com/girishji/vimsuggest)** plugin.


# Requirements

- Vim version 9.0 or higher

# Installation

Install it via [vim-plug](https://github.com/junegunn/vim-plug).

<details><summary><b>Show instructions</b></summary>
<br>
  
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
<br>
  
```bash
$ mkdir -p $HOME/.vim/pack/downloads/opt
$ cd $HOME/.vim/pack/downloads/opt
$ git clone https://github.com/girishji/vimcomplete.git
```

Add the following line to your $HOME/.vimrc file.

```vim
packadd vimcomplete
```

</details>

# Configuration

The completion sources mentioned above, aside from [buffer](#Buffer-Completion), [path](#path-completion), and [lsp](#lsp-completion) completion, are not enabled by default. This section provides instructions on configuring both the completion sources and the completion engine itself.

## Completion Engine

This entity retrieves completion items from the enabled completion sources and then displays the popup menu.

Option|Type|Description
------|----|-----------
`alwaysOn`|`Boolean`| If set to `true`, the completion menu is automatically triggered by any change in the buffer. If set to `false`, use `<C-Space>` (control-space) to manually trigger auto-completion. If you choose to map some other key instead, map your favorite key to `<Plug>(vimcomplete-do-complete)`. Default: true.
`completionKinds`|`Dictionary`|Custom text to use when `customCompletionKinds` is set (explained below). Default: `{}`.
`customCompletionKinds`|`Boolean`|Set this option to customize the 'kind' attribute (explained below). Default: `false`.
`customInfoWindow`|`Boolean`|Change the look of default info popup window (explained below). Default: `true`.
`kindDisplayType`|`String`|The 'kind' field of completion item can be displayed in a number of ways: as a single letter symbol (`symbol`), a single letter with descriptive text (`symboltext`), only text (`text`), an icon (`icon`), or icon with text (`icontext`). For showing VSCode like icons you need [a patched font](https://www.nerdfonts.com/). Default: `symbol`.
`matchCase`|`Boolean`|Prioritize the items that match the case of the prefix being completed. Default: `true`.
`noNewlineInCompletion` | `Boolean` | When `true`, pressing `<Enter>` (`<CR>`) in insert mode will insert a newline only if an item in the popup menu is selected. If an item is not selected, the popup is dismissed without inserting a newline. Default: `false`.
`noNewlineInCompletionEver` | `Boolean` | When `true`, pressing `<Enter>` (`<CR>`) will never insert a newline, regardless of whether an item in the popup menu is selected. This option overrides `noNewlineInCompletion`. If both options are `false`, `<CR>` behaves as per the default Vim behavior, inserting a newline whether an item is selected or not. Default: `false`.
`postfixClobber` | `Boolean` | When completing 'foo\<cursor\>bar' and the candidate is 'foosome', enabling this option (`true`) will complete 'foosome' instead of 'foosomebar'. Default: `false`.
`postfixHighlight` | `Boolean` | This option functions similarly to `postfixClobber`, but instead of deleting adjoining text to the right of the completed text, it highlights it using the 'VimCompletePostfix' highlight group. Use `<C-l>` to delete the adjoining text. Default: `false`.
`recency`|`Boolean`|Display recently chosen items from the LRU cache. Items are shown at the top of the list. Default: `true`.
`recentItemCount`|`Number`|Count of recent items to show from LRU cache. Default: `5`.
`showKind`|`Boolean`|Show the type ('kind') of completion item returned by LSP server. Default: `true`.
`showSource`|`Boolean`|Show the source of the completion item in the menu. Default: `true`.
`shuffleEqualPriority`|`Boolean`|Arrange items from sources with equal priority such that the first item of all sources appear before the second item of any source. Default: `false`.
`sortByLength`|`Boolean`|Sort completion items by length. Default: `false`.
`triggerWordLen`|`Number`|Minimum number of characters needed to trigger completion menu. Not applicable to completion triggered by LSP trigger characters. Default: `1`.

## Buffer Completion

The current buffer, as well as other open buffers, are searched for completion candidates using an asynchronous mechanism with a timeout. This approach ensures that the completion engine is not slowed down by large buffers.

Option|Type|Description
------|----|-----------
`completionMatcher`| `String` | Enable fuzzy or case insensitive completion. Accepts one of the following values: `case` for case sensitive matching, `icase` for ignoring case while matching, and `fuzzy` for fuzzy match. Default: `icase`.
`dup`|`Boolean`|If true, include items from this source that are duplicates of items from other sources. Default: `true`.
`enable`|`Boolean`|Set this to `false` to disable buffer completion. Default: `true`.
`envComplete`      | `Boolean` | Complete environment variables after typing the `$` character. Default: `false`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']` (all file types).
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`otherBuffersCount`| `Number`  | Maximum number of other listed buffers to search. Set it to `0` to only search current buffer. Default: `3`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.
`timeout`          | `Number`  | Maximum time allocated for searching completion candidates in the current buffer. Default: `100` milliseconds. If searching in multiple buffers, an additional 100 milliseconds is allocated. The search is aborted if any key is pressed.
`urlComplete`      | `Boolean` | Enable completion of http links in entirety. This is useful when typing the same URL multiple times. Default: `false`.

## Dictionary Completion

The dictionary provider is capable of searching an arbitrary list of words placed one per line in a text file. These words can encompass any non-space characters, and the file doesn't necessarily need to be sorted. This feature presents various opportunities. For instance, you can create a dictionary akin to [Pydiction](https://github.com/vim-scripts/Pydiction), enabling the completion of keywords, functions, and method names for any programming language. Moreover, it can efficiently search a sorted dictionary using binary search.

Unsorted dictionaries are searched in linear time `O(n)`, but they tend to perform acceptably well for file sizes below 3MB (performance might vary depending on your system). Only one unsorted dictionary is used for completion, while any number of sorted dictionaries can be used simultaneously.

Additionally, the dictionary files can include comments.


Option|Type|Description
------|----|-----------
`commentStr`       | `String` | Any lines beginning with this string is ignored. Default: `---`.
`dup`|`Boolean`|If true, include items from this source that are duplicates of items from other sources. Default: `false`.
`enable`|`Boolean`|Set this to `true` to enable dictionary completion. Default: `false`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['text', 'markdown']`.
`matcher`| `String` | This option is active only when `onlyWords` is `true` (text files). It makes sense only when `sortedDict` is set to `false` since binary search is done case sensitive (assuming that sorting of the dictionary file is done case sensitive). Accepted values are `case` (case sensitive) and `ignorecase`. Default: `case`.
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`onlyWords`| `Boolean` | Set this to `true` if both the prefix you are trying to complete and the dictionary contain alphanumeric characters only (text files). For programming language dictionaries it should be set to `false`, since they can contain characters like `@`, `.`, `(`, etc. Default: `false`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.
`sortedDict`       | `Boolean` | `true` if the dictionary file is sorted, `false` otherwise. This option affects both performance and correctness. Take care to set it correctly. Searching is case sensitive. Default: `true`.

### Sample Configuration

Further information about setting up configurations will be available later. Nonetheless, here is a sample configuration specifically targeting the dictionary source.

Dictionary files can be configured individually for each 'filetype' (`:h filetype`). In the provided sample, the dictionary module is enabled for filetypes 'python' and 'text'. Vim `dictionary` option is appropriately set. Specific dictionary options are defined for each respective filetype.

```
vim9script
var dictproperties = {
    python: { sortedDict: false },
    text: { sortedDict: true }
}
var vcoptions = {
    dictionary: { enable: true, priority: 11, filetypes: ['python', 'text'], properties: dictproperties },
}
autocmd VimEnter * g:VimCompleteOptionsSet(vcoptions)
autocmd FileType text set dictionary+=/usr/share/dict/words
autocmd FileType python set dictionary=$HOME/.vim/data/pythondict
```

> [!TIP]
> For completing English words, you can utilize [ngram](https://en.wikipedia.org/wiki/N-gram) completion as outlined below, or opt for a custom dictionary containing frequently used words. Unfortunately, the default dictionary that comes pre-installed with Linux or MacOS contains numerous infrequently used words that spam the menu.

> [!NOTE]
> For legacy script, the syntax for 'autocmd' is:
> ```
> autocmd VimEnter * call g:VimCompleteOptionsSet(vcoptions)
> ```

## LSP Completion

This source obtains autocompletion items from the
[LSP client](https://github.com/yegappan/lsp).

> [!IMPORTANT]
> Please install the [LSP client](https://github.com/yegappan/lsp) separately.

Option|Type|Description
------|----|-----------
`dup`|`Boolean`|If true, include items from this source that are duplicates of items from other sources. Default: `true`.
`enable`|`Boolean`|Set this to `false` to disable LSP completion. Default: `true`.
`filetypes`|`List`|This option need not be specified. If this option is not specified or is empty, completion items are sourced for any file type for which LSP is configured. Otherwise, items are sourced only for listed file types. Default: Not specified.
`keywordOnly`|`Boolean`|If `true` completion will be triggered after any keyword character as defined by the file type (`:h 'iskeyword'`). `false` will trigger completion after non-keywords like `.` (for instance). Default: `false`.
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.

> [!NOTE]
> For fuzzy and case insensitive completion, set the `completionMatcher` option in the [LSP client](https://github.com/yegappan/lsp). See `:h lsp-opt-completionMatcher`.

## Snippets Completion

This source provides snippet completion from [vim-vsnip](https://github.com/hrsh7th/vim-vsnip).

> [!IMPORTANT]
> Please install the following separately.
> - [vim-vsnip](https://github.com/hrsh7th/vim-vsnip)
> - [vim-vsnip-integ](https://github.com/hrsh7th/vim-vsnip-integ)
>
> Optional:
> - [friendly-snippets](https://github.com/rafamadriz/friendly-snippets)


Option|Type|Description
------|----|-----------
`adaptNonKeyword`|`Boolean`|(experimental) When completing snippets starting with non-keywords, say '#i' for instance, adjust completion such that they are compatible with items starting with keywords like 'i' (returned by LSP, for instance). Default is `false`.
`dup`|`Boolean`|If true, include items from this source that are duplicates of items from other sources. Default: `true`.
`enable`|`Boolean`|Set this to `true` to enable this source. Default: `false`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']` (all file types).
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.

> [!NOTE]
> The `<Tab>` key facilitates movement within a snippet. When a snippet is active, the popup completion menu won't open. However, the popup window will activate upon reaching the final stop within the snippet. If you wish to navigate backward within the snippet using `<S-Tab>`, you can dismiss the popup by using `CTRL-E`.


## Ngrams Completion

This source is kept as a separate plugin since it includes large database
files. Please see
**[ngram-complete](https://github.com/girishji/ngram-complete.vim)** for
installation and usage instructions.

## Omnifunc Completion

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
> Disable the <a href="#lsp-completion">LSP Completion</a> when using omnifunc.

Option|Type|Description
------|----|-----------
`dup`|`Boolean`|If true, include items from this source that are duplicates of items from other sources. Default: `true`.
`enable`|`Boolean`|Set this to `true` to enable omnifunc completion. Default: `false`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']` (all file types).
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`.

## Path Completion

Both relative and absolute path names are completed.

| Option              | Type      | Description   |
|---------------------|-----------|---------------|
| `bufferRelativePath`| `Boolean` | Interpret relative paths relative to the directory of the current buffer. Otherwise paths are interpreted relative to the directory from which Vim is started. Default: `true`.    |
| `dup`|`Boolean`|If true, include items from this source that are duplicates of items from other sources. Default: `true`. |
| `enable`|`Boolean`|Set this to `false` to disable path completion. Default: `true`. |
| `filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']` (all file types). |
| `groupDirectoriesFirst`| `Boolean` | Group directories before files (like linux's 'ls --group-directories-first'). Default: `false`.    |
| `maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`. |
| `priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `12`. |
| `showPathSeparatorAtEnd`| `Boolean` | Show path separator (`/` in unix) at the end of directory entry. Default: `false`.    |

> [!NOTE]
> Path completion activates when there is a `/` (`\` for Windows when Vim option `shellslash` is not set) or `.` in the word before the cursor. To autocomplete deeper in a directory type `/` at the end.

## Abbreviations Completion

Abbreviations (`:h abbreviations`) are completed based on the `id`.

| Option              | Type      | Description   |
|---------------------|-----------|---------------|
| `dup`|`Boolean`|If true, include items from this source that are duplicates of items from other sources. Default: `true`. |
| `enable`|`Boolean`|Set this to `true` to enable abbreviation completion. Default: `false`. |
| `filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']` (all file types). |
| `maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`. |
| `priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`. |

## Vim9script Language Completion

This source completes Vim9 script function names, arguments, variables, reserved words and
the like. Enable this if you are developing a Vim plugin or configuring a non-trivial _.vimrc_.


| Option              | Type      | Description   |
|---------------------|-----------|---------------|
| `dup`|`Boolean`|If true, include items from this source that are duplicates of items from other sources. Default: `true`. |
| `enable`|`Boolean`|Set this to `false` to disable this source. Default: `true`. |
| `filetypes`|`List`|List of file types for which this source is enabled. Default: `['vim']`. |
| `maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`. |
| `priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `10`. |

## Tmux Completion

Words are sourced asynchronously from adjacent tmux panes, ensuring Vim won't hang even with a lot of output in the tmux windows.

Option|Type|Description
------|----|-----------
`completionMatcher`| `String` | Enable fuzzy or case insensitive completion. Accepts one of the following values: `case` for case sensitive matching, `icase` for ignoring case while matching, and `fuzzy` for fuzzy match. Default: `icase`.
`dup`|`Boolean`|If true, include items from this source that are duplicates of items from other sources. Default: `false`.
`enable`|`Boolean`|Set this to `true` to enable tmux completion. Default: `false`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']`.
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`name`|`String`|Name of the executable. You can specify the full path if the *tmux* executable is not found in $PATH. Default: `tmux`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `8`.
`scrollCount`| `Number` | Number of lines above visible lines to search for words. Excludes visible lines if Vim is running in a pane. Default: 200.

## Tag Completion

Tag names are autocompleted if tags file is available.

Option|Type|Description
------|----|-----------
`enable`|`Boolean`|Set this to `true` to enable tag name completion. Default: `false`.
`filetypes`|`List`|List of file types for which this source is enabled. Default: `['*']`.
`maxCount`|`Number`|Total number of completion candidates emitted by this source. Default: `10`.
`priority`|`Number`|Priority of this source relative to others. Items from higher priority sources are displayed at the top. Default: `8`.

## Configure Options

Options can be configured using the global function `g:VimCompleteOptionsSet()`. The example below illustrates how to enable and configure completion sources. Please note that not all options are demonstrated here; for a comprehensive list of all available options, refer to the tables provided above.

```vim
vim9script
var options = {
    completor: { shuffleEqualPriority: true, postfixHighlight: true },
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

> [!NOTE]
> For legacy script, the syntax for 'autocmd' is:
> ```
> autocmd VimEnter * call g:VimCompleteOptionsSet(options)
> ```

## Tab Completion

You can map the `<Tab>` and `<S-Tab>` keys to navigate autocomplete items in insert mode. By default, Vim uses `CTRL-N` and `CTRL-P` to cycle through completion menu options. `<Tab>` and `<S-Tab>` also jump between snippet placeholders where appropriate.

To enable `<Tab>` and `<S-Tab>` for this purpose, add the following to your configuration:

```vim
vim9script
let g:vimcomplete_tab_enable = 1
```

> **Note**: Enabling this option will remove any existing mappings for `<Tab>` and `<S-Tab>`.

If you'd like to retain `<Tab>` and `<S-Tab>` mappings from other plugins, unset the above variable and instead use these custom mappings, substituting `{rhs}` as needed (using `"\<Tab>"` as `"{rhs}"` will behave the same as setting the variable):

```vim
inoremap <buffer><expr> <tab>   g:VimCompleteTab() ?? "{rhs}"
inoremap <buffer><expr> <s-tab> g:VimCompleteSTab() ?? "{rhs}"
```

This configuration allows `<Tab>` and `<S-Tab>` to integrate with other plugin mappings.

Alternatively, you can use the keys `<Plug>(vimcomplete-tab)` and `<Plug>(vimcomplete-s-tab)` directly in your custom mappings.

## Enter Key Handling

`<Enter>` is mapped by default to insert the currently selected item and/or insert a literal `<CR>`, depending on configuration (see `noNewlineInCompletion` and `noNewlineInCompletionEver` options).

In case of conflicts with other plugins, this mapping can be disabled entirely:

```vim
vim9script
g:vimcomplete_cr_enable = 0
```

In this case, the user must define an appropriate `<CR>` mapping to resolve conflicts between plugins. When creating your mapping, if `alwaysOn` is enabled, consider emitting `<Plug>(vimcomplete-skip)` to prevent the next keystroke from automatically reactivating the completion popup.

> [!NOTE]
> For help with other keybindings see `:h popupmenu-keys`. This help section includes keybindings for `<BS>`, `CTRL-H`, `CTRL-L`, `CTRL-Y`, `CTRL-E`, `<PageUp>`, `<PageDown>`, `<Up>`, and `<Down>` keys when popup menu is open.

## Highlight Groups

You can use `Pmenu`, `PmenuThumb`, `PmenuSbar`, `PmenuSel`, `PmenuKind`,
`PmenuKindSel`, `PmenuExtra` and `PmenuExtraSel` Vim highlight groups to alter the
appearance of the popup menu.

You can also customize the appearance of the column containing the 'kind' attribute in the menu. For example, to modify the appearance of the 'Keyword' kind, configure the `PmenuKindKeyword` highlight group. Refer to the [list](#Custom-Completion-Kinds) for all available 'kind' items.

If `postfixHighlight` option is enabled, you can utilize the `VimCompletePostfix` highlight group to adjust the appearance of text adjacent to the completion. By default, it is linked to `DiffChange`.

## Info Popup Window

Vim's completion system opens an additional popup window next to the selected
item if the item has additional info that needs to be displayed. If you prefer to keep the
default look of this window set `customInfoWindow` to `false`. Set it to `true` to see a more
refined border. If you prefer to customize this window further use
`g:VimCompleteInfoPopupOptionsSet()`. It takes a dictionary of popup window
options. See `:h popup_create-arguments`. You can set `borderchars`,
`borderhighlight` and `popuphighlight` for instance.

# Commands

Commands are available to list completion sources and to enable or disable the plugin.

## Listing Completion Sources

The following command displays a list of completion sources enabled for the current buffer.

```vim
:VimCompleteCompletors
```

## Enable and Disable

Autocompletion is enabled by default. At any time, you can enable or disable the plugin using the following commands:

```vim
:VimCompleteEnable
:VimCompleteDisable
```

You can selectively enable autocompletion for specific _file types_. For instance, enable autocompletion for `c`, `cpp`, `python`, `vim`, `text`, and `markdown` files.

```vim
:VimCompleteEnable c cpp python vim text markdown
```

To start Vim with autocompletion disabled, set the following variable.

```vim
g:vimcomplete_enable_by_default = false
```

`VimCompleteEnable` takes a space-separated list of _file types_ as an argument. If no argument is specified, autocompletion is enabled for _all file types_.

When Vim is started without any arguments or a new buffer is created with
`:bufnew`, it opens an unnamed buffer. This buffer is not associated with any
_file type_. To enable/disable autocompletion on this buffer use the following
variable. It is set by default.

```vim
g:vimcomplete_noname_buf_enable = true
```

# Custom Completion Kinds

Each item returned by the LSP server has a type associated with it, which can
be displayed on the popup menu. To customize , you need to use the option
`customCompletionKinds` and set all custom kinds in the `completionKinds`.
The following table has all default LSP kinds:

Kind|Description
----|-----------
t | Text
m | Method
f | Function
C | Constructor
F | Field
v | Variable
c | Class
i | Interface
M | Module
p | Property
u | Unit
V | Value
e | Enum
k | Keyword
S | Snippet
C | Color
f | File
r | Reference
F | Folder
E | EnumMember
d | Constant
s | Struct
E | Event
o | Operator
T | TypeParameter
B | Buffer[^2]
D | Dictionary[^2]
w | Word[^2]
O | Option[^2]
a | Abbreviation[^2]
e | EnvVariable[^2]
U | URL[^2]
c | Command[^2]
X | Tmux[^2]
G | Tag[^2]

[^2]: This is not returned by LSP.

For example, if you want to change the "Method" kind to the kind "method()":

```vim
vim9script
g:VimCompleteOptionsSet({ Completor: {
    customCompletionKinds: true,
    completionKinds: {
        "Method": "method()"
    }
})

In the completion popup, will show something like this: >

    var file = new File()

    file.cre
        | create                method() |
        | createIfNotExists     method() |
        | ...                            |
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

# Other Plugins to Enhance Your Workflow

1. [**Devdocs.vim**](https://github.com/girishji/devdocs.vim) - browse documentation from [devdocs.io](https://devdocs.io).

2. [**Scope.vim**](https://github.com/girishji/scope.vim) - fuzzy find anything.

3. [**VimBits**](https://github.com/girishji/vimbits) - curated suite of lightweight Vim plugins.

4. [**VimSuggest**](https://github.com/girishji/vimsuggest) - autocompletion for Vim's command-line.

# Contributing

Pull requests are welcomed.

# Similar Vim Plugins

- [asyncomplete](https://github.com/prabirshrestha/asyncomplete.vim)
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

