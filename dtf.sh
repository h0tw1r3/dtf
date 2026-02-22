# shellcheck shell=sh
#
# MIT License
# Copyright (c) 2021 Jeffrey Clark <https://github.com/h0tw1r3>

alias _dtf='/usr/bin/env git --git-dir="$_DTF_WORKDIR" --work-tree="$HOME"'

_dtf_msg() {
    printf >&2 "%s: %s" "$_DTF_FN" "$*\n"
}

_dtf_clear() {
    unset _DTF_FN
    unset _DTF_WORKDIR
    unset _DTF_INIT
    unset _DTF_RCFILE
}

_dtf_output_url() {
    if ! curl --connect-timeout 5 -L -sSf -o "${2}" "${1}" ; then
        if ! wget --timeout 5 --tries=1 -qO "${2}" "${1}"; then
            _dtf_msg "failed to download: ${1}"
            return 1
        fi
    fi
}

dtf() {
    export _DTF_FN="dtf"
    export _DTF_WORKDIR="$HOME/.${_DTF_FN}"
    DTF_URL=${DTF_URL:-https://github.com/h0tw1r3/dtf/raw/main/dtf.sh}
    DTF_BRANCH=${DTF_BRANCH:-main}
    if [ ! -f "${_DTF_WORKDIR}/config" ] ; then
        if ! _dtf init "$_DTF_WORKDIR" >/dev/null ; then
            _dtf_msg "failed to init repo"
            _dtf_clear ; return 1
        fi
        _DTF_INIT=1
    fi
    if [ "${_DTF_INIT:-$DTF_CHECKS}" -eq 1 ] ; then
        if [ "$(_dtf config --local --get status.showUntrackedFiles)" != "no" ] ; then
            if ! _dtf config --local status.showUntrackedFiles no ; then
                _dtf_msg "config set failed"
                _dtf_clear ; return 1
            fi
        fi
        if ! _dtf remote get-url origin >/dev/null 2>&1 ; then
            if [ -z "${DTF_REPO:-}" ] ; then
                _dtf_msg "DTF_REPO not set! Please set it to the git URL of the repository to use."
                _dtf_clear ; return 1
            fi
            if ! _dtf remote add origin "$DTF_REPO" ; then
                _dtf_msg "failed to add remote origin $DTF_REPO"
                _dtf_clear ; return 1
            fi
        fi
        if [ ! -d "${_DTF_WORKDIR}/refs/remotes/origin" ] ; then
            if ! _dtf fetch origin ; then
                _dtf_msg "failed to fetch remote"
                _dtf_clear ; return 1
            fi
        fi
        if [ -z "${DTF_AUTORC:-}" ] || [ "${DTF_AUTORC:-}" = "1" ] ; then
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
        else
            _dtf_msg "DTF_AUTORC is disabled, skipping shell source setup."
            _dtf_msg "Manually add '. \"\$HOME/.${_DTF_FN}.sh\"' to your shell rc file."
        fi
        if [ "${_DTF_INIT:-}" = "1" ] ; then
            _dtf reset --hard "origin/${DTF_BRANCH}" && \
            _dtf submodule update --init --recursive
        fi
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
            _dtf_clear ; return 1
        fi
        _dtf_clear ; return
    fi

    _dtf "$@"
}

# vim:syntax=sh filetype=sh expandtab ts=4 sw=4
