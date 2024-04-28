vim9script

import autoload './util.vim'

export var options: dict<any> = {
    enable: false,
    dup: false,
    maxCount: 10,
    scrollCount: 200,
    completionMatcher: 'icase', # 'case', 'fuzzy', 'icase'
    name: 'tmux',
}

def ActivePane(): string
    var cmd = options.name .. ' list-panes -a -F "#{pane_id}" -f "#{==:#{window_active}#{pane_active},11}" 2>/dev/null'
    return system(cmd)->trim()
enddef

def Panes(exclude_current: bool = false): string
    var cmd = $'{options.name} list-panes -a -F "#{{pane_id}}"'
    if exclude_current
        cmd ..= ' -f "#{!=:#{window_active}#{pane_active},11}"'
    endif
    cmd ..= ' 2>/dev/null'
    var lst = systemlist(cmd)
    return lst->join(' ')
enddef

def CaptureCmd(): string
    var cmd = $'{options.name} capture-pane -J -p -S -{options.scrollCount}'  # visible lines plus scroll scrollCount lines above
    if $TMUX_PANE != null_string  # running inside tmux
        var cmd_active = $'{cmd} -E -1 -t {ActivePane()}'  # scroll scrollCount lines above first line (for active pane)
        var panes = Panes(true)
        if panes != null_string
            return $'sh -c "{cmd_active}; for p in {panes}; do {cmd} -t $p; done 2>/dev/null"'
        endif
    else
        var panes = Panes()
        if panes != null_string
            return $'sh -c "for p in {panes}; do {cmd} -t $p; done 2>/dev/null"'
        endif
    endif
    return null_string
enddef

var items = []
var start = reltime()
var status = 0  # 0 not ready, 1 finished, 2 has some intermediate completions
var job: job

def JobStart()
    # ch_logfile('/tmp/channellog', 'w')
    # ch_log('BuildItemsList call')
    var cmd = CaptureCmd()
    if cmd != null_string
        job = job_start(cmd, {
            out_cb: (ch, str) => {
                # out_cb is invoked when channel reads a line; if you don't care
                # about intermediate output use close_cb
                items->extend(str->split())
                if start->reltime()->reltimefloat() * 1000 > 100  # update every 100ms
                    status = 2
                    start = reltime()
                endif
            },
            close_cb: (ch) => {
                status = 1
            },
            err_cb: (chan: channel, msg: string) => {
                status = 1
                :echohl ErrorMsg | echoerr $'error: {msg} from {cmd}' | echohl None
            },
        })
    endif
enddef

export def Completor(findstart: number, base: string): any
    if findstart == 1
        var line = getline('.')->strpart(0, col('.') - 1)
        var prefix = line->matchstr('\k\+$')
        if line =~ '\s$' || prefix->empty() || 'tmux'->exepath() == null_string
            return -2
        endif
        items = []
        start = reltime()
        if job->job_status() ==# 'run'
            job->job_stop()
        endif
        status = 0
        JobStart()
        return col('.') - prefix->len()
    elseif findstart == 2
        if status == 2
            status = 0
            return 2
        endif
        return status
    else
        var candidates = []
        if options.completionMatcher == 'fuzzy'
            candidates = items->matchfuzzy(base)
        else
            var icase = options.completionMatcher == 'icase'
            candidates = items->copy()->filter((_, v) => v !=# base
                && ((icase && v->tolower()->stridx(base) == 0) || (!icase && v->stridx(base) == 0)))
        endif
        candidates = candidates->slice(0, options.maxCount)
        var kind = util.GetItemKindValue('Tmux')
        return candidates->mapnew((_, v) => {
            return { word: v, kind: kind, dup: (options.dup ? 1 : 0) }
        })
    endif
enddef
