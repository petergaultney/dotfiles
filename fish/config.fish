if not status is-interactive
    return
end

set -gx RIPGREP_CONFIG_PATH "$HOME/.config/.ripgreprc"
set -gx HOMEBREW_NO_AUTO_UPDATE 1
set -gx EDITOR emacsclient -t
set -gx PIPENV_VENV_IN_PROJECT 1
set -gx THDS_CORE_LOG_LEVELS_FILE "$HOME/work/.thds_log_levels.txt"
set -gx SKIP mono-docker-lock

set -l dotfiles_path_dirs \
    "$HOME/sw/bin" \
    "$HOME/.atuin/bin" \
    "$HOME/.local/share/mise/shims" \
    "$HOME/.local/bin" \
    "$HOME/.cargo/bin" \
    "/Applications/Obsidian.app/Contents/MacOS" \
    "/opt/homebrew/bin" \
    "/usr/local/bin" \
    "$HOME/Applications/Docker.app/Contents/Resources/bin"
for dotfiles_path in $dotfiles_path_dirs[-1..1]
    if test -d "$dotfiles_path"
        set -gx PATH "$dotfiles_path" $PATH
    end
end

if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end
if test -f "$HOME/.config/fish/config.local.fish"
    source "$HOME/.config/fish/config.local.fish"
end

alias rename 'wezterm cli rename-workspace'
alias la 'ls -la'
alias ll 'ls -l'
alias lh 'ls -lah'
alias gs 'git status'
alias gca 'git commit -a'
alias gcma 'git commit -a -m'
alias gsw 'git switch'
alias gpf 'git push --force-with-lease'
alias cb 'env NODE_NO_WARNINGS=1 clawdbot tui'
alias edaemon 'emacs --daemon'
alias e 'emacsclient -t'
alias ea "emacsclient --eval '(abort-recursive-edit)'"
alias esh 'emacsclient -t -e "(eshell t)"'
alias edir 'emacsclient -t -e "(dired default-directory)"'
alias c 'claude --remote-control --allow-dangerously-skip-permissions --thinking-display summarized'
alias lp 'lemonaid place'
alias rr 'poetry run'
alias pr 'pipenv run'
alias pylsp-install 'uv run pip install python-lsp-server pylsp-mypy pyls-isort python-lsp-black'
alias ptx 'uv run pytest -n auto --cov --cov-report=html'
alias vv 'uv run'
alias us 'uv sync'
alias vip 'uv run --with ipython ipython'
alias mi 'uv run mops-inspect'
alias pst 'uv run pytest tests'
alias ohslack 'killall Slack; open -a Slack'
alias tailscale '/Applications/Tailscale.app/Contents/MacOS/Tailscale'
alias adu 'uv run adls-download-uri'
alias adu-clip 'uv run adls-download-uri (pbpaste)'
alias lroc 'lemonaid openclaw register'

function e --description 'Open a file in Emacs or Emacs vterm'
    if set -q EMACS_VTERM_PATH
        if test (count $argv) -gt 0
            __dotfiles_vterm_printf "51;Ee $argv"
        else
            echo 'Usage: e <filename>'
        end
    else
        emacsclient -t $argv
    end
end

function gd --description 'Show a diff using difft'
    env GIT_EXTERNAL_DIFF=difft git diff $argv
end

function edaemon_pid
    set -l pid (ps aux | rg -i 'emacs --.*daemon' | rg -v rg | awk '{print $2}')
    if test -z "$pid"
        echo 'Could not find emacs daemon pid!' >&2
        return 1
    end
    echo $pid
end

function edaemon_interrupt
    kill -SIGUSR2 (edaemon_pid)
end

function ked
    kill -9 (edaemon_pid)
end

function fix-emacs
    kill -USR2 (edaemon_pid)
    emacsclient --eval '(abort-recursive-edit)'
end

function pcr
    env SKIP=mono-docker-lock pre-commit run $argv
end

function mst
    uv run dmypy run --timeout 3600 -- . --config-file pyproject.toml $argv
end

function ulimit_n
    ulimit -n $argv[1]
end

function cd_repo_root
    set -l root (command git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$root"
        cd "$root"
    else
        echo 'No git repo found'
        return 1
    end
end

function mon
    set -l original_dir $PWD
    cd_repo_root; or return
    uv run mono $argv
    set -l result $status
    cd "$original_dir"
    return $result
end

function sd --description 'Run a command and speak its result'
    if test (count $argv) -eq 0
        echo 'Usage: sd COMMAND [ARG ...]' >&2
        return 2
    end
    set -l current_dir (basename "$PWD")
    $argv
    set -l result $status
    if test $result -eq 0
        say "done in $current_dir"
    else
        say "failed in $current_dir"
    end
    return $result
end

function __dotfiles_env_name
    if set -q VIRTUAL_ENV_DISABLE_PROMPT
        return
    end
    if set -q VIRTUAL_ENV_PROMPT
        printf '%s' "$VIRTUAL_ENV_PROMPT"
        return
    end
    set -l env_name
    if set -q VIRTUAL_ENV
        set env_name (basename "$VIRTUAL_ENV")
    else if set -q CONDA_DEFAULT_ENV
        set env_name $CONDA_DEFAULT_ENV
    end
    if test -n "$env_name"
        printf '(%s)' "$env_name"
    end
end

function __dotfiles_short_cwd
    set -l path "$PWD"
    if test "$PWD" = "$HOME"
        set path '~'
    else if string match -q "$HOME/*" "$PWD"
        set path (string replace "$HOME/" '~/' "$PWD")
    end
    set -l prefix ''
    if string match -q '/*' "$path"
        set prefix '/'
        set path (string sub -s 2 "$path")
    end
    set -l parts (string split / "$path")
    set -l last_index (count $parts)
    for index in (seq $last_index)
        if test $index -lt $last_index
            if test "$parts[$index]" != '~' -a -n "$parts[$index]"
                set parts[$index] (string sub -l 1 "$parts[$index]")
            end
        end
    end
    printf '%s%s' "$prefix" (string join / $parts)
end

function __dotfiles_git_branch
    command git symbolic-ref --quiet --short HEAD 2>/dev/null
end

function fish_prompt
    set -l last_status $status
    set_color ffaf00
    printf '<%s' (date '+%H:%M:%S')
    if set -q CMD_DURATION; and test $CMD_DURATION -gt 1000
        set_color yellow
        printf ' %.2fs' (math --scale=2 $CMD_DURATION / 1000)
    end
    set_color ffaf00
    printf '> '
    printf '%s' (__dotfiles_env_name)
    set_color --bold blue
    printf '%s ' (__dotfiles_short_cwd)
    set -l branch (__dotfiles_git_branch)
    if test -n "$branch"
        set_color 5dd8c8
        printf '%s ' "$branch"
    end
    if test $last_status -ne 0
        set_color red
        printf 'rv:%s ' $last_status
    end
    set_color --bold magenta
    printf '$'
    set_color normal
    printf ' '
    __dotfiles_vterm_prompt
    __dotfiles_emit_osc7
end

function __dotfiles_emit_osc7
    set -q TMUX; or return
    printf '\e]7;file://%s%s\a' (hostname) "$PWD" > /dev/tty 2>/dev/null
end

function __dotfiles_vterm_printf
    set -l payload $argv[1]
    set -l term $TERM
    if set -q TMUX; and string match -qr '^(tmux|screen)' -- "$term"
        printf '\ePtmux;\e\e]%s\a\e\\' "$payload"
    else if string match -qr '^screen' -- "$term"
        printf '\eP\e]%s\a\e\\' "$payload"
    else
        printf '\e]%s\e\\' "$payload"
    end
end

function __dotfiles_vterm_prompt
    set -q EMACS_VTERM_PATH; or return
    set -l escaped_pwd (string escape --style=script "$PWD/")
    __dotfiles_vterm_printf "51;E\"update-pwd\" \"$escaped_pwd\""
    __dotfiles_vterm_printf "51;A$USER@(hostname):$PWD"
end

function __dotfiles_pwd_changed --on-variable PWD
    __dotfiles_emit_osc7
end

__dotfiles_emit_osc7

if test -x "$HOME/.atuin/bin/atuin"
    "$HOME/.atuin/bin/atuin" init fish --disable-up-arrow | source
end

if string match -q 'mercy-m1*' (hostname)
    if command -q zoxide
        zoxide init fish | source
    end
end
