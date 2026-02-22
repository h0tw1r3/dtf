# shellcheck shell=sh
#
# MIT License
# Copyright (c) 2021 Jeffrey Clark <https://github.com/h0tw1r3>

alias _dtf='/usr/bin/env git --git-dir="$_DTF_WORKDIR" --work-tree="$HOME"'

_dtf_msg() {
    echo >&2 "${_DTF_FN}: $*"
}

_dtf_output_url() {
    if command -v curl >/dev/null ; then
        curl --connect-timeout 5 -L -sSf -o "${2}" "${1}";
    else
        wget --timeout 5 --tries=1 -qO "${2}" "${1}";
    fi
}

dtf() {
    export _DTF_FN="dtf"
    export _DTF_WORKDIR="$HOME/.${_DTF_FN}"
    DTF_CHECKS=${DTF_CHECKS:-1}
    DTF_URL=${DTF_URL:-https://github.com/h0tw1r3/dtf/raw/main/dtf.sh}
    DTF_BRANCH=${DTF_BRANCH:-main}
    if [ -z "$DTF_REPO" ] ; then
        echo >&2 "${_DTF_FN}: DTF_REPO not set"
        return 1
    else
        if [ ! -f "${_DTF_WORKDIR}/config" ] ; then
            if ! _dtf init "$_DTF_WORKDIR" >/dev/null ; then
                _dtf_msg "failed to init repo"
                return 1
            fi
            _DTF_INIT=1
            DTF_CHECKS=1
        fi
        if [ "${DTF_CHECKS}" -eq 1 ] ; then
            if [ "$(_dtf config --local --get status.showUntrackedFiles)" != "no" ] ; then
                if ! _dtf config --local status.showUntrackedFiles no ; then
                    _dtf_msg "config set failed"
                    return 1
                fi
            fi
            if ! _dtf remote get-url origin >/dev/null 2>&1 ; then
                if ! _dtf remote add origin "$DTF_REPO" ; then
                    _dtf_msg "failed to add remote origin $DTF_REPO"
                    return 1
                fi
            fi
            if [ ! -d "${_DTF_WORKDIR}/refs/remotes/origin" ] ; then
                if ! _dtf fetch origin ; then
                    _dtf_msg "failed to fetch remote"
                    return 1
                fi
            fi
            # add to POSIX (ash, ksh), bash, and zsh rc files
            if [ -n "${ENV:-}" ] ; then
                _DTF_RCFILE="$ENV"
            elif [ -n "${BASH_VERSION:-}" ] ; then
                _DTF_RCFILE="$HOME/.bashrc"
            elif [ -n "${ZSH_VERSION:-}" ] ; then
                _DTF_RCFILE="$HOME/.zshrc"
            fi

            if ! grep -qF ". \"\$HOME/.${_DTF_FN}.sh\"" "$_DTF_RCFILE" 2>/dev/null ; then
                [ -f "$_DTF_RCFILE" ] || touch "$_DTF_RCFILE"
                echo ". \"\$HOME/.${_DTF_FN}.sh\"" >> "$_DTF_RCFILE"
            fi
            unset _DTF_RCFILE
        fi
        if [ -n "${_DTF_INIT:-}" ] ; then
            _dtf reset --hard "origin/${DTF_BRANCH}"
            _dtf submodule update --init --recursive
            unset _DTF_INIT
        fi
        _DTF_TREF=$(_dtf for-each-ref --format='%(upstream:short)' "$(_dtf symbolic-ref -q HEAD)")
        if [ "${_DTF_TREF}" != "origin/${DTF_BRANCH}" ] ; then
            unset _DTF_TREF
            if ! _dtf branch -u "origin/${DTF_BRANCH}" ; then
                # TODO check if new repo
                _dtf_msg "failed to track origin/${DTF_BRANCH}, new repository?"
                return 1
            fi
            _dtf submodule update --recursive
        fi
        unset _DTF_TREF
    fi
    if [ ! -f ~/."$_DTF_FN".sh ] ; then
        _dtf_msg "shell source is missing!? Please run '${_DTF_FN} upgrade' to install it again."
    elif [ "$*" = "upgrade" ] ; then
        if _dtf_output_url "${DTF_URL}" ~/."$_DTF_FN".sh.$$ ; then
            # shellcheck source=/dev/null
            . ~/".$_DTF_FN".sh.$$ && \
                cat ~/."$_DTF_FN".sh.$$ > ~/."$_DTF_FN".sh && \
                rm -f ~/."$_DTF_FN".sh.$$
        else
            _dtf_msg "upgrade failed"
            return 1
        fi
        return
    fi

    _dtf "$@"
}

# vim:syntax=sh filetype=sh expandtab ts=4 sw=4
