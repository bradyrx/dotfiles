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

# Bail out, if not running interactively (e.g. when sending data packets over with scp/rsync)
# Known bug, scp/rsync fail without this line due to greeting message:
# 1) https://unix.stackexchange.com/questions/88602/scp-from-remote-host-fails-due-to-login-greeting-set-in-bashrc
# 2) https://unix.stackexchange.com/questions/18231/scp-fails-without-error
[[ $- != *i* ]] && return
clear # first clear screen

# Prompt
# Keep things minimal, just make prompt boldface so its a bit more identifiable
if [ -z "$_ps1_set" ]; then # don't overwrite modifications by supercomputer modules, conda environments, etc.
  export PS1='\[\033[1;37m\]\h[\j]:\W\$ \[\033[0m\]' # prompt string 1; shows "<comp name>:<work dir> <user>$"
  _ps1_set=1
fi

# Message constructor; modify the number to increase number of dots
# export PS1='\[\033[1;37m\]\h[\j]:\W \u\$ \[\033[0m\]' # prompt string 1; shows "<comp name>:<work dir> <user>$"
  # style; the \[ \033 chars are escape codes for changing color, then restoring it at end
  # see: https://stackoverflow.com/a/28938235/4970632
  # also see: https://unix.stackexchange.com/a/124408/112647
_bashrc_message() {
  printf "${1}$(printf '.%.0s' $(seq 1 $((29 - ${#1}))))"
}

#-----------------------------------------------------------------------------#
# Settings for particular machines
# Custom key bindings and interaction
#-----------------------------------------------------------------------------#
# Reset all aliases
# Very important! Sometimes we wrap new aliases around existing ones, e.g. ncl!
unalias -a

# Flag for if in MacOs
[[ "$OSTYPE" == "darwin"* ]] && _macos=true || _macos=false

# Python stuff
# Must set PYTHONBUFFERED or else running bash script that invokes python will
# prevent print statements from getting flushed to stdout until exe finishes
unset PYTHONPATH
export PYTHONUNBUFFERED=1

# First, the path management
_bashrc_message "Variables and modules"
if $_macos; then
  # Defaults, LaTeX, X11, Homebrew, Macports, PGI compilers, and local compilations
  # NOTE: Added ffmpeg with sudo port install ffmpeg +nonfree
  # NOTE: Added matlab as a symlink in builds directory
  # NOTE: Install gcc and gfortran with 'port install gcc6' then
  # 'port select --set gcc mp-gcc6' (check 'port select --list gcc')
  export PATH=$(tr -d $'\n ' <<< "
    $HOME/builds/ncl-6.5.0/bin:$HOME/builds/matlab/bin:
    /opt/pgi/osx86-64/2018/bin:
    /usr/local/bin:
    /opt/local/bin:/opt/local/sbin:
    /opt/X11/bin:/Library/TeX/texbin:
    /usr/bin:/bin:/usr/sbin:/sbin:
    ")
  export LM_LICENSE_FILE="/opt/pgi/license.dat-COMMUNITY-18.10"
  export PKG_CONFIG_PATH="/opt/local/bin/pkg-config"

  # Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
  # WARNING: Need to install with rvm! Get endless issues with MacPorts/Homebrew
  # versions! See: https://stackoverflow.com/a/3464303/4970632
  # Test with: ruby -ropen-uri -e 'eval open("https://git.io/vQhWq").read'
  # Install rvm with: \curl -sSL https://get.rvm.io | bash -s stable --ruby
  if [ -d ~/.rvm/bin ]; then
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
    export PATH="$PATH:$HOME/.rvm/bin"
    rvm use ruby 1>/dev/null
  fi

  # NCL NCAR command language, had trouble getting it to work on Mac with conda
  # NOTE: By default, ncl tried to find dyld to /usr/local/lib/libgfortran.3.dylib;
  # actually ends up in above path after brew install gcc49; and must install
  # this rather than gcc, which loads libgfortran.3.dylib and yields gcc version 7
  # Tried DYLD_FALLBACK_LIBRARY_PATH but it screwed up some python modules
  alias ncl='DYLD_LIBRARY_PATH="/opt/local/lib/libgcc" ncl' # fix libs
  export NCARG_ROOT="$HOME/builds/ncl-6.5.0" # critically necessary to run NCL

else
  case $HOSTNAME in
  # Cheyenne supercomputer, any of the login nodes
  cheyenne*)
    # Edit library path
    # Set tmpdir following direction of: https://www2.cisl.ucar.edu/user-support/storing-temporary-files-tmpdir
    export LD_LIBRARY_PATH="/glade/u/apps/ch/opt/netcdf/4.6.1/intel/17.0.1/lib:$LD_LIBRARY_PATH"
    export TMPDIR=/glade/scratch/$USER/tmp
    # Load some modules
    # NOTE: Use 'qinteractive' for interactive mode
    _loaded=($(module --terse list 2>&1)) # already loaded
    _toload=(nco tmux cdo ncl)
    for _module in ${_toload[@]}; do
      if [[ ! " ${_loaded[@]} " =~ "$_module" ]]; then
        module load $_module
      fi
    done
  ;; *) echo "\"$HOSTNAME\" does not have custom settings. You may want to edit your \".bashrc\"."
  ;; esac
fi

# Access custom executables and git repos
# e.g., ack.
export PATH=$(tr -d $'\n ' <<< "
  $HOME/bin:
  $PATH
  ")

# Save path before setting up conda
# Brew conflicts with anaconda (try "brew doctor" to see)
alias brew="PATH=\"$PATH\" brew"

# Matplotlib stuff
# May be necessary for rendering fonts in ipython notebooks
# See: https://github.com/olgabot/sciencemeetproductivity.tumblr.com/blob/master/posts/2012/11/how-to-set-helvetica-as-the-default-sans-serif-font-in.md
export MPLCONFIGDIR=$HOME/.matplotlib
printf "done\n"

#-----------------------------------------------------------------------------#
# Anaconda stuff
#-----------------------------------------------------------------------------#
unset _conda
if [ -d "$HOME/anaconda3" ]; then
  _conda='anaconda3'
elif [ -d "$HOME/miniconda3" ]; then
  _conda='miniconda3'
fi
if [ -n "$_conda" ] && ! [[ "$PATH" =~ "conda" ]]; then # above doesn't work, need to just check path
  # For info on what's going on see: https://stackoverflow.com/a/48591320/4970632
  # The first thing creates a bunch of environment variables and functions
  # The second part calls the 'conda' function, which calls an activation function, which does the
  # whole solving environment thing
  # If you use the '. activate' version, there is an 'activate' file in bin
  # that does these two things
  _bashrc_message "Enabling conda"
  source $HOME/$_conda/etc/profile.d/conda.sh # set up environment variables
  CONDA_CHANGEPS1=false conda activate # activate the default environment, without changing PS1
  avail() {
    local current latest
    [ $# -ne 1 ] && echo "Usage: avail PACKAGE" && return 1
    current=$(conda list "$1" | grep '\b'"$1"'\b' | awk 'NR == 1 {print $2}')
    latest=$(conda search "$1" | grep '\b'"$1"'\b' | awk 'END {print $2}')
    echo "Package:         $1"
    echo "Current version: $current"
    echo "Latest version:  $latest"
    }
  printf "done\n"
fi

#-----------------------------------------------------------------------------#
# Wrappers for common functions
#-----------------------------------------------------------------------------#
_bashrc_message "Functions and aliases"
# Environment variables
export EDITOR=vim # default editor, nice and simple
export LC_ALL=en_US.UTF-8 # needed to make Vim syntastic work

#-----------------------------------------------------------------------------#
# SHELL BEHAVIOR, KEY BINDINGS
#-----------------------------------------------------------------------------#
# Readline/inputrc settings
# Use Ctrl-R to search previous commands
# Equivalent to putting lines in single quotes inside .inputrc
# bind '"\C-i":glob-expand-word' # expansion but not completion
_setup_bindings() {
  complete -r # remove completions
  bind -r '"\C-i"'
  bind -r '"\C-d"'
  bind -r '"\C-s"' # to enable C-s in Vim (normally caught by terminal as start/stop signal)
  bind 'set disable-completion off'          # ensure on
  bind 'set completion-ignore-case on'       # want dat
  bind 'set completion-map-case on'          # treat hyphens and underscores as same
  bind 'set show-all-if-ambiguous on'        # one tab press instead of two; from this: https://unix.stackexchange.com/a/76625/112647
  bind 'set menu-complete-display-prefix on' # show string typed so far as 'member' while cycling through completion options
  bind 'set completion-display-width 1'      # easier to read
  bind 'set bell-style visible'              # only let readlinke/shell do visual bell; use 'none' to disable totally
  bind 'set skip-completed-text on'          # if there is text to right of cursor, make bash ignore it; only bash 4.0 readline
  bind 'set visible-stats off'               # extra information, e.g. whether something is executable with *
  bind 'set page-completions off'            # no more --more-- pager when list too big
  bind 'set completion-query-items 0'        # never ask for user confirmation if there's too much stuff
  bind 'set mark-symlinked-directories on'   # add trailing slash to directory symlink
  bind '"\C-i": menu-complete'               # this will not pollute scroll history; better
  bind '"\e-1\C-i": menu-complete-backward'  # this will not pollute scroll history; better
  bind '"\e[Z": "\e-1\C-i"'                  # shift tab to go backwards
  bind '"\C-l": forward-char'
  bind '"\C-s": beginning-of-line' # match vim motions
  bind '"\C-e": end-of-line'       # match vim motions
  bind '"\C-h": backward-char'     # match vim motions
  bind '"\C-w": forward-word'      # requires
  bind '"\C-b": backward-word'     # by default c-b moves back one word, and deletes it
  bind '"\eOP": menu-complete'          # history
  bind '"\eOQ": menu-complete-backward' # history
  bind '"\C-j": next-history'
  bind '"\C-k": previous-history'  # history
  bind '"\C-j": next-history'
  bind '"\C-p": previous-history'  # history
  bind '"\C-n": next-history'
  stty werase undef # no more ctrl-w word delete function; allows c-w re-binding to work
  stty stop undef   # no more ctrl-s
  stty eof undef    # no more ctrl-d
}
_setup_bindings 2>/dev/null # ignore any errors

# Shell Options
# Check out 'shopt -p' to see possibly interesting shell options
# Note diff between .inputrc and .bashrc settings: https://unix.stackexchange.com/a/420362/112647
_setup_opts() {
  # Turn off history expansion, so can use '!' in strings; see: https://unix.stackexchange.com/a/33341/112647
  set +H
  # No more control-d closing terminal
  set -o ignoreeof
  # Disable start/stop output control
  stty -ixon # note for putty, have to edit STTY value and set ixon to zero in term options
  # Exit this script when encounter error, and print each command; useful for debugging
  # set -ex
  # Various shell options
  shopt -s cmdhist                 # save multi-line commands as one command in shell history
  shopt -s checkwinsize            # allow window resizing
  shopt -u nullglob                # turn off nullglob; so e.g. no null-expansion of string with ?, * if no matches
  shopt -u extglob                 # extended globbing; allows use of ?(), *(), +(), +(), @(), and !() with separation "|" for OR options
  shopt -u dotglob                 # include dot patterns in glob matches
  shopt -s direxpand               # expand dirs
  shopt -s dirspell                # attempt spelling correction of dirname
  shopt -s cdspell                 # spelling errors during cd arguments
  shopt -s cdable_vars             # cd into shell variable directories, no $ necessary
  shopt -s nocaseglob              # case insensitive
  shopt -s autocd                  # typing naked directory name will cd into it
  shopt -s no_empty_cmd_completion # no more completion in empty terminal!
  shopt -s histappend              # append to the history file, don't overwrite it
  shopt -s cmdhist                 # save multi-line commands as one command
  shopt -s globstar                # **/ matches all subdirectories, searches recursively
  shopt -u failglob                # turn off failglob; so no error message if expansion is empty
  # shopt -s nocasematch # don't want this; affects global behavior of case/esac, and [[ =~ ]] commands
  # Related environment variables
  export HISTIGNORE="&:[ ]*:return *:exit *:cd *:source *:. *:bg *:fg *:history *:clear *" # don't record some commands
  export PROMPT_DIRTRIM=2 # trim long paths in prompt
  export HISTSIZE=50000
  export HISTFILESIZE=10000 # huge history -- doesn't appear to slow things down, so why not?
  export HISTCONTROL="erasedups:ignoreboth" # avoid duplicate entries
}
_setup_opts 2>/dev/null # ignore if option unavailable

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