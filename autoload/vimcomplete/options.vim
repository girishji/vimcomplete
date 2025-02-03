vim9script

# Completor options

export var options: dict<any> = {
    noNewlineInCompletion: false,
    noNewlineInCompletionEver: false,
    matchCase: true,
    sortByLength: false,
    recency: true,
    recentItemCount: 5,
    shuffleEqualPriority: false,
    alwaysOn: true,
    setCompleteOpt: true,
    showCmpSource: true,
    cmpSourceWidth: 4,
    showKind: true,
    customCompletionKinds: false,
    completionKinds: {},
    kindDisplayType: 'symbol', # 'icon', 'icontext', 'text', 'symboltext', 'symbol', 'text'
    postfixClobber: false,  # remove yyy in xxx<cursor>yyy
    postfixHighlight: false, # highlight yyy in xxx<cursor>yyy
    triggerWordLen: 0,
    infoPopup: true,
    throttleTimeout: 1,
    debug: false,
}

