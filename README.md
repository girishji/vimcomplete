#### Async Autocompletion for Vim

A lightweight autocompletion plugin written entirely in Vim9
script.

# Features

- Code completion using [LSP](https://github.com/yegappan/lsp)
- Snippet completion using [vsnip](https://github.com/hrsh7th/vim-vsnip)
- Buffer word completion; Can search multiple buffers
- Dictionary completion using [ngrams](https://github.com/girishji/ngram-complete.vim)
- Dictionary completion using configured dictionary (`:h 'dictionary'`)
- [Vimscript language completion](https://github.com/girishji/vimscript-complete.vim) (like LSP)
- Path completion
- Abbreviation completion (`:h abbreviations`)
- Very responsive and will not hang (asynchronous completion)

Each of the above completion options can be configured for specific file types.

In addition, completion items can be sorted based on:

- Recency (how recently item was chosen in the past)
- length of item
- priority
- locality of item (in case of keywords from buffer)
- case match

For cmdline-mode completion see [autosuggest](https://github.com/girishji/autosuggest.vim).

# 
