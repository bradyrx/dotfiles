#!/bin/bash
#.bashrc
#-----------------------------------------------------------------------------#
# This file should override defaults in /etc/profile in /etc/bashrc.
# Check out what is in the system defaults before using this, make sure your
# $PATH is populated. To SSH between servers without password use:
# https://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/
# A few notes:
#  * Prefix key for issuing SSH-session commands is '~'; 'exit' sometimes doesn't work (perhaps because
#    if aliased or some 'exit' is in $PATH
#     C-d/'exit' -- IF AVAILABLE, exit SSH session
#     ~./~C-z -- Exit SSH session
#     ~& -- Puts SSH into background
#     ~# -- Gives list of forwarded connections in this session
#     ~? -- Gives list of these commands
#  * Extended globbing explanations, see:
#     http://mywiki.wooledge.org/glob
#  * Use '<package_manager> list' for MOST PACKAGE MANAGERS to see what is installed
#     e.g. brew list, conda list, pip list
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# General utilties
#-----------------------------------------------------------------------------#
# Configure ls behavior, define colorization using dircolors
if [ -r "$HOME/.dircolors.ansi" ]; then
  $_macos && _dc_command=gdircolors || _dc_command=dircolors
  eval "$($_dc_command $HOME/.dircolors.ansi)"
fi
$_macos && _ls_command=gls || _ls_command=ls
alias ls="$_ls_command --color=always -AF"   # ls useful (F differentiates directories from files)
alias ll="$_ls_command --color=always -AFhl" # ls "list", just include details and file sizes
alias cd="cd -P" # don't want this on my mac temporarily
alias ctags="ctags --langmap=vim:+.vimrc,sh:+.bashrc" # permanent lang maps
log() {
  while ! [ -r "$1" ]; do
    echo "Waiting..."
    sleep 2
  done
  tail -f "$1"
}

# Standardize less/man/etc. colors
# Used this: https://unix.stackexchange.com/a/329092/112647
export LESS="--RAW-CONTROL-CHARS"
[ -f ~/.LESS_TERMCAP ] && . ~/.LESS_TERMCAP
if hash tput 2>/dev/null; then
  export LESS_TERMCAP_md=$'\e[1;33m'     # begin blink
  export LESS_TERMCAP_so=$'\e[01;44;37m' # begin reverse video
  export LESS_TERMCAP_us=$'\e[01;37m'    # begin underline
  export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
  export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
  export LESS_TERMCAP_ue=$'\e[0m'        # reset underline
  export GROFF_NO_SGR=1                  # for konsole and gnome-terminal
fi