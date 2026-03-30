# shellcheck shell=sh
#
# MIT License
# Copyright (c) 2021 Jeffrey Clark <https://github.com/h0tw1r3>

_dtf() {
    _dtf_debug /usr/bin/env git --git-dir="$_DTF_WORKDIR" --work-tree="$HOME" "$*"
    /usr/bin/env git --git-dir="$_DTF_WORKDIR" --work-tree="$HOME" "$@"
}

_dtf_msg() {
    _DT_MSG_TEMP="%s: %s"
    if [ "$1" != "-n" ]; then
        _DT_MSG_TEMP="${_DT_MSG_TEMP}\n"
    else
        shift
    fi
    # shellcheck disable=SC2059
    printf >&2 "${_DT_MSG_TEMP}" "$_DTF_FN" "$*"
    unset _DT_MSG_TEMP
}

_dtf_debug() {
    if [ -n "${DTF_DEBUG}" ]; then
        _dtf_msg "[debug] $*"
    fi
}

_dtf_clear() {
    unset _DTF_FN
    unset _DTF_WORKDIR
    unset _DTF_RCFILE
    # shellcheck disable=SC2046
    set -- $(set | while IFS= read -r _line; do
        case "$_line" in
            _DTF_CONFIG*=*)
                printf '%s ' "${_line%%=*}"
                ;;
        esac
    done)
    if [ $# -gt 0 ]; then
        unset "$@"
    fi

}

_dtf_output_url() {
    if ! curl --connect-timeout 5 -L -sSf -o "${2}" "${1}"; then
        if ! wget --timeout 5 --tries=1 -qO "${2}" "${1}"; then
            _dtf_msg "failed to download: ${1}"
            return 1
        fi
    fi
}

_dtf_config() {
    if [ "$1" = "--set" ]; then
        # Usage: --set <full.git.key> <value>
        [ -z "$3" ] && return 1
        _dtf config --local "$2" "$3"
        set -- "$2" "$3"
    else
        # Usage: <full.git.key> [default_fallback]
        [ -z "$1" ] && return 1
        set -- "$1" "$(_dtf config --local --get "$1" 2>/dev/null || printf '%s' "$2")"
    fi

    # $1: original key (e.g. filters.xyz.smudge)
    # $2: the value
    # $3: sanitized suffix (FILTERS_XYZ_SMUDGE)
    # tr converts lowercase to uppercase and swaps '.' and '-' for '_'
    set -- "$1" "$2" "$(printf '%s' "$1" | tr '[:lower:].-' '[:upper:]__')"

    if [ -n "$2" ]; then
        eval "_DTF_CONFIG_$3=\"\$2\""
    fi
}

# Returns branch name in _dtf_branch, 0 on success, 1 on failure.
_dtf_detect_branch() {
    _dtf_debug "detecting branch"
    _dtf_branch=""
    [ -n "${DTF_BRANCH:-}" ] && _dtf rev-parse "origin/${DTF_BRANCH}" >/dev/null 2>&1 \
        && {
            _dtf_branch="$DTF_BRANCH"
            return 0
        }
    [ -n "${DTF_BRANCH:-}" ] && {
        _dtf_msg "branch '${DTF_BRANCH}' not found on remote"
        return 1
    }

    _dtf_heads="" _dtf_count=0 _dtf_preferred=""
    while IFS= read -r _dtf_line; do
        _dtf_rest="${_dtf_line#*refs/heads/}"
        [ "$_dtf_rest" = "$_dtf_line" ] && continue
        _dtf_b="${_dtf_rest%%*[ 	]*}"
        [ -z "$_dtf_b" ] && continue
        case "
${_dtf_heads}
" in *"
${_dtf_b}
"*) continue ;; esac
        _dtf_heads="${_dtf_heads}${_dtf_heads:+
}${_dtf_b}"
        _dtf_count=$((_dtf_count + 1))
        case "$_dtf_b" in main) _dtf_preferred="main" ;; master) [ -z "$_dtf_preferred" ] && _dtf_preferred="master" ;; esac
    done <<EOF
$(_dtf ls-remote origin 'refs/heads/*' 2>/dev/null)
EOF
    unset _dtf_line _dtf_rest _dtf_b

    [ "${_dtf_count:-0}" -eq 0 ] && {
        _dtf_msg "no branches found on remote (empty repo)"
        unset _dtf_heads _dtf_count _dtf_preferred
        return 1
    }
    [ "${_dtf_count:-0}" -eq 1 ] && {
        for _dtf_b in $_dtf_heads; do
            _dtf_branch="$_dtf_b"
            break
        done
        unset _dtf_heads _dtf_count _dtf_preferred _dtf_b
        return 0
    }
    [ -n "${_dtf_preferred:-}" ] && {
        _dtf_branch="$_dtf_preferred"
        unset _dtf_heads _dtf_count _dtf_preferred
        return 0
    }
    if [ -t 0 ]; then
        _dtf_msg "multiple branches found; choose one:"
        _dtf_n=1
        for _dtf_b in $_dtf_heads; do
            _dtf_msg "  $_dtf_n) $_dtf_b"
            _dtf_n=$((_dtf_n + 1))
        done
        printf >&2 "dtf: selection (1-%d): " "$((_dtf_n - 1))"
        read -r _dtf_sel 2>/dev/null || true
        _dtf_n=1
        for _dtf_b in $_dtf_heads; do
            if [ "${_dtf_sel:-}" = "$_dtf_n" ] || [ "${_dtf_sel:-}" = "$_dtf_b" ]; then
                _dtf_branch="$_dtf_b"
                unset _dtf_heads _dtf_count _dtf_preferred _dtf_n _dtf_b _dtf_sel
                return 0
            fi
            _dtf_n=$((_dtf_n + 1))
        done
        _dtf_msg "invalid selection"
        unset _dtf_heads _dtf_count _dtf_preferred _dtf_n _dtf_b _dtf_sel
        return 1
    fi
    _dtf_msg "multiple branches found. Set DTF_BRANCH or run in a terminal to choose."
    unset _dtf_heads _dtf_count _dtf_preferred
    return 1
}

dtf() {
    export _DTF_FN="dtf"
    export _DTF_WORKDIR="$HOME/.${_DTF_FN}"
    DTF_URL=${DTF_URL:-https://github.com/h0tw1r3/dtf/raw/main/dtf.sh}
    if [ ! -f "${_DTF_WORKDIR}/config" ]; then
        _dtf_debug "config does not exist, init repo"
        if ! _dtf init "$_DTF_WORKDIR" >/dev/null; then
            _dtf_msg "failed to init repo"
            _dtf_clear
            return 1
        fi
    fi

    _dtf_config dtf.initialized no

    if [ "$_DTF_CONFIG_DTF_INITIALIZED" != "yes" ]; then
        _dtf_debug "initializing"
        _dtf_config --set status.showUntrackedFiles no
        _dtf_config --set filter.chmod-user-only.smudge 'chmod 0600 %f; cat'
        if ! _dtf remote get-url origin >/dev/null 2>&1; then
            _dtf_debug "remote origin not set"
            if [ -n "${DTF_REPO:-}" ]; then
                _dtf_debug "adding remote origin: ${DTF_REPO}"
                if ! _dtf remote add origin "$DTF_REPO"; then
                    _dtf_msg "failed to add remote origin $DTF_REPO"
                    _dtf_clear
                    return 1
                fi
            else
                _dtf_msg "Local repo initialized. Add a remote later with: dtf remote add origin <url>"
                _dtf_config --set dtf.initialized yes
            fi
        fi

        if [ "$_DTF_CONFIG_DTF_INITIALIZED" != "yes" ]; then
            _dtf_debug "fetching origin"
            if _dtf fetch origin 2>/dev/null; then
                if ! _dtf_detect_branch; then
                    _dtf_msg "Failed to determine branch, unable to checkout."
                    _dtf_clear
                    return 1
                fi
                if ! _dtf reset --hard "origin/${_dtf_branch}"; then
                    _dtf_msg "Fatal error checking out branch 'origin/${_dtf_branch}'"
                    _dtf_clear
                    return 1
                fi
                if ! _dtf branch -m "${_dtf_branch}"; then
                    _dtf_msg "Fatal error setting current branch name"
                    _dtf_clear
                    return 1
                fi
                if ! _dtf branch --set-upstream-to="origin/${_dtf_branch}" "${_dtf_branch}"; then
                    _dtf_msg "Error tracking branch 'origin/${_dtf_branch}' to '${_dtf_branch}'"
                    _dtf_clear
                    return 1
                fi
                if ! _dtf submodule update --init --recursive; then
                    _dtf_msg "Warning, failed to initialize submodules, continuing anyway"
                fi
                unset _dtf_branch
            else
                _dtf remote remove origin 2>/dev/null
                _dtf_msg "Warning, failed to fetch DTF_REPO (${DTF_REPO}). Continuing with local-only repo. Add remote later when accessible: dtf remote add origin <url>"
            fi
        fi

        if [ -z "${DTF_AUTORC:-}" ] || [ "${DTF_AUTORC:-}" = "1" ]; then
            # add to POSIX (ash, ksh), bash, and zsh rc files
            if [ -n "${ENV:-}" ]; then
                _DTF_RCFILE="$ENV"
            elif [ -f ~/.commonrc ]; then
                _DTF_RCFILE="$HOME/.commonrc"
            elif [ -n "${BASH_VERSION:-}" ]; then
                _DTF_RCFILE="$HOME/.bashrc"
            elif [ -n "${ZSH_VERSION:-}" ]; then
                _DTF_RCFILE="$HOME/.zshrc"
            else
                _dtf_msg "unknown shell, cannot determine rc file for source setup"
                _dtf_clear
                return 1
            fi

            if ! grep -qF ". \"\$HOME/.${_DTF_FN}.sh\"" "$_DTF_RCFILE" 2>/dev/null; then
                [ -f "$_DTF_RCFILE" ] || touch "$_DTF_RCFILE"
                echo ". \"\$HOME/.${_DTF_FN}.sh\"" >>"$_DTF_RCFILE"
            fi
            unset _DTF_RCFILE
        else
            _dtf_msg "DTF_AUTORC is disabled, skipping shell source setup."
            _dtf_msg "Manually add '. \"\$HOME/.${_DTF_FN}.sh\"' to your shell rc file."
        fi

        _dtf_config --set dtf.initialized yes
    fi
    if [ ! -f ~/."$_DTF_FN".sh ]; then
        _dtf_msg "shell source is missing!? Please run '${_DTF_FN} upgrade' to install it again."
    elif [ "$*" = "upgrade" ]; then
        _dtf_msg -n "downloading... "
        if _dtf_output_url "${DTF_URL}" ~/."$_DTF_FN".sh.$$; then
            _dtf_msg -n "upgrading... "
            # shellcheck source=/dev/null
            . ~/".$_DTF_FN".sh.$$ \
                && cat ~/."$_DTF_FN".sh.$$ >~/."$_DTF_FN".sh \
                && rm -f ~/."$_DTF_FN".sh.$$
        else
            _dtf_msg "failed"
            _dtf_clear
            return 1
        fi
        _dtf_msg "success"
        _dtf_clear
        return
    fi

    _dtf "$@"
}

# vim:syntax=sh filetype=sh expandtab ts=4 sw=4
