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
# Bash_it config
#-----------------------------------------------------------------------------#
# Path to the bash it configuration
export BASH_IT=$HOME/.bash_it
export BASH_IT_THEME='sexy'
export GIT_HOSTING='git@github.com'
export EDITOR="vim"
export GIT_EDITOR='vim'
# Don't check mail when opening terminal.
unset MAILCHECK
source $BASH_IT/bash_it.sh

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

# Neat function that splits lines into columns so they fill the terminal window
_columnize() {
  local cmd
  local input output final
  local tcols ncols maxlen nlines
  [ $# -eq 0 ] && input=$(cat /dev/stdin) || input="$1"
  ! $_macos && cmd=wc || cmd=gwc
  ncols=1 # start with 1
  tcols=$(tput cols)
  maxlen=0 # initial
  nlines=$(printf "$input" | $cmd -l) # check against initial line count
  output="$input" # default
  while true; do
    final="$output" # record previous output, this is what we will print
    output=$(printf "$input" | xargs -n$ncols | column -t)
    maxlen=$(printf "$output" | $cmd -L)
    # maxlen=$(printf "$output" | awk '{print length}' | sort -nr | head -1) # or wc -L but that's unavailable on mac
    [ $maxlen -gt $tcols ] && break # this time *do not* print latest result, will result in line break due to terminal edge
    [ $ncols -gt $nlines ] && final="$output" && break # test *before* increment, want to use that output
    # echo terminal $tcols ncols $ncols nlines $nlines maxlen $maxlen
    let ncols+=1
  done
  printf "$final"
}

# Environment variables
export EDITOR=vim # default editor, nice and simple
export LC_ALL=en_US.UTF-8 # needed to make Vim syntastic work

# #-----------------------------------------------------------------------------#
# # SHELL BEHAVIOR, KEY BINDINGS
# #-----------------------------------------------------------------------------#
# # Readline/inputrc settings
# # Use Ctrl-R to search previous commands
# # Equivalent to putting lines in single quotes inside .inputrc
# # bind '"\C-i":glob-expand-word' # expansion but not completion
# _setup_bindings() {
#   complete -r # remove completions
#   bind -r '"\C-i"'
#   bind -r '"\C-d"'
#   bind -r '"\C-s"' # to enable C-s in Vim (normally caught by terminal as start/stop signal)
#   bind 'set disable-completion off'          # ensure on
#   bind 'set completion-ignore-case on'       # want dat
#   bind 'set completion-map-case on'          # treat hyphens and underscores as same
#   bind 'set show-all-if-ambiguous on'        # one tab press instead of two; from this: https://unix.stackexchange.com/a/76625/112647
#   bind 'set menu-complete-display-prefix on' # show string typed so far as 'member' while cycling through completion options
#   bind 'set completion-display-width 1'      # easier to read
#   bind 'set bell-style visible'              # only let readlinke/shell do visual bell; use 'none' to disable totally
#   bind 'set skip-completed-text on'          # if there is text to right of cursor, make bash ignore it; only bash 4.0 readline
#   bind 'set visible-stats off'               # extra information, e.g. whether something is executable with *
#   bind 'set page-completions off'            # no more --more-- pager when list too big
#   bind 'set completion-query-items 0'        # never ask for user confirmation if there's too much stuff
#   bind 'set mark-symlinked-directories on'   # add trailing slash to directory symlink
#   bind '"\C-i": menu-complete'               # this will not pollute scroll history; better
#   bind '"\e-1\C-i": menu-complete-backward'  # this will not pollute scroll history; better
#   bind '"\e[Z": "\e-1\C-i"'                  # shift tab to go backwards
#   bind '"\C-l": forward-char'
#   bind '"\C-s": beginning-of-line' # match vim motions
#   bind '"\C-e": end-of-line'       # match vim motions
#   bind '"\C-h": backward-char'     # match vim motions
#   bind '"\C-w": forward-word'      # requires
#   bind '"\C-b": backward-word'     # by default c-b moves back one word, and deletes it
#   bind '"\eOP": menu-complete'          # history
#   bind '"\eOQ": menu-complete-backward' # history
#   bind '"\C-j": next-history'
#   bind '"\C-k": previous-history'  # history
#   bind '"\C-j": next-history'
#   bind '"\C-p": previous-history'  # history
#   bind '"\C-n": next-history'
#   stty werase undef # no more ctrl-w word delete function; allows c-w re-binding to work
#   stty stop undef   # no more ctrl-s
#   stty eof undef    # no more ctrl-d
# }
# _setup_bindings 2>/dev/null # ignore any errors

# # Shell Options
# # Check out 'shopt -p' to see possibly interesting shell options
# # Note diff between .inputrc and .bashrc settings: https://unix.stackexchange.com/a/420362/112647
# _setup_opts() {
#   # Turn off history expansion, so can use '!' in strings; see: https://unix.stackexchange.com/a/33341/112647
#   set +H
#   # No more control-d closing terminal
#   set -o ignoreeof
#   # Disable start/stop output control
#   stty -ixon # note for putty, have to edit STTY value and set ixon to zero in term options
#   # Exit this script when encounter error, and print each command; useful for debugging
#   # set -ex
#   # Various shell options
#   shopt -s cmdhist                 # save multi-line commands as one command in shell history
#   shopt -s checkwinsize            # allow window resizing
#   shopt -u nullglob                # turn off nullglob; so e.g. no null-expansion of string with ?, * if no matches
#   shopt -u extglob                 # extended globbing; allows use of ?(), *(), +(), +(), @(), and !() with separation "|" for OR options
#   shopt -u dotglob                 # include dot patterns in glob matches
#   shopt -s direxpand               # expand dirs
#   shopt -s dirspell                # attempt spelling correction of dirname
#   shopt -s cdspell                 # spelling errors during cd arguments
#   shopt -s cdable_vars             # cd into shell variable directories, no $ necessary
#   shopt -s nocaseglob              # case insensitive
#   shopt -s autocd                  # typing naked directory name will cd into it
#   shopt -s no_empty_cmd_completion # no more completion in empty terminal!
#   shopt -s histappend              # append to the history file, don't overwrite it
#   shopt -s cmdhist                 # save multi-line commands as one command
#   shopt -s globstar                # **/ matches all subdirectories, searches recursively
#   shopt -u failglob                # turn off failglob; so no error message if expansion is empty
#   # shopt -s nocasematch # don't want this; affects global behavior of case/esac, and [[ =~ ]] commands
#   # Related environment variables
#   export HISTIGNORE="&:[ ]*:return *:exit *:cd *:source *:. *:bg *:fg *:history *:clear *" # don't record some commands
#   export PROMPT_DIRTRIM=2 # trim long paths in prompt
#   export HISTSIZE=50000
#   export HISTFILESIZE=10000 # huge history -- doesn't appear to slow things down, so why not?
#   export HISTCONTROL="erasedups:ignoreboth" # avoid duplicate entries
# }
# _setup_opts 2>/dev/null # ignore if option unavailable

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
alias la="$_ls_command --color=always -AFla"
alias lh="$_ls_command --color=always -AFlhtr"
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

# Information on directories
$_macos || alias hardware="cat /etc/*-release" # print out Debian, etc. release info
$_macos || alias cores="cat /proc/cpuinfo | awk '/^processor/{print \$3}' | wc -l"
# Directory sizes, normal and detailed, analagous to ls/ll
alias df="df -h" # disk useage
alias du='du -h -d 1' # also a better default du
ds() {
  local dir
  [ -z $1 ] && dir="." || dir="$1"
  find "$dir" -maxdepth 1 -mindepth 1 -type d -print | sed 's|^\./||' | sed 's| |\\ |g' | _columnize
}
dl() {
  local cmd dir
  [ -z $1 ] && dir="." || dir="$1"
  ! $_macos && cmd=sort || cmd=gsort
  find "$dir" -maxdepth 1 -mindepth 1 -type d -exec du -hs {} \; | sed $'s|\t\./|\t|' | sed 's|^\./||' | $cmd -sh
}

# Grepping and diffing; enable colors
alias grep="grep --exclude-dir=_site --exclude-dir=plugged --exclude-dir=.git --exclude-dir=.svn --color=auto"
alias egrep="egrep --exclude-dir=_site --exclude-dir=plugged --exclude-dir=.git --exclude-dir=.svn --color=auto"

# git-completion
if [ -f ~/dotfiles/.git-completion.bash ]; then
  . ~/dotfiles/.git-completion.bash
fi

#-----------------------------------------------------------------------------#
# Aliases/functions for printing out information
#-----------------------------------------------------------------------------#
# The -X show bindings bound to shell commands (i.e. not builtin readline functions, but strings specifying our own)
# The -s show bindings 'bound to macros' (can be combination of key-presses and shell commands)
# NOTE: Example for finding variables:
# for var in $(variables | grep -i netcdf); do echo ${var}: ${!var}; done
# NOTE: See: https://stackoverflow.com/a/949006/4970632
alias aliases="compgen -a"
alias variables="compgen -v"
alias functions="compgen -A function" # show current shell functions
alias builtins="compgen -b" # bash builtins
alias commands="compgen -c"
alias keywords="compgen -k"
alias modules="module avail 2>&1 | cat "
if $_macos; then
  alias bindings="bind -Xps | egrep '\\\\C|\\\\e' | grep -v 'do-lowercase-version' | sort" # print keybindings
  alias bindings_stty="stty -e"                # bindings
else
  alias bindings="bind -ps | egrep '\\\\C|\\\\e' | grep -v 'do-lowercase-version' | sort" # print keybindings
  alias bindings_stty="stty -a"                # bindings
fi
alias inputrc_ops="bind -v"           # the 'set' options, and their values
alias inputrc_funcs="bind -l"         # the functions, for example 'forward-char'
env() { set; } # just prints all shell variables

#-----------------------------------------------------------------------------#
# Supercomputer tools
#-----------------------------------------------------------------------------#
alias suser="squeue -u $USER"
alias sjobs="squeue -u $USER | tail -1 | tr -s ' ' | cut -s -d' ' -f2 | tr -d '[:alpha:]'"

# Kill PBS processes all at once; useful when debugging stuff, submitting teeny
# jobs. The tail command skips first (n-1) lines.
qkill() {
  local proc
  for proc in $(qstat | tail -n +3 | cut -d' ' -f1 | cut -d. -f1); do
    qdel $proc
    echo "Deleted job $proc"
  done
}

#-----------------------------------------------------------------------------#
# Dataset utilities
#-----------------------------------------------------------------------------#
# NetCDF tools (should just remember these)
# NCKS behavior very different between versions, so use ncdump instead
# * Note if HDF4 is installed in your anaconda distro, ncdump will point to *that location* before
#   the homebrew install location 'brew tap homebrew/science, brew install cdo'
# * This is bad, because the current version can't read netcdf4 files; you really don't need HDF4,
#   so just don't install it
# Summaries first
nchelp() {
  echo "Available commands:"
  echo "ncinfo ncglobal ncvars ncdims
        ncin nclist ncvarlist ncdimlist
        ncvarinfo ncvardump ncvartable ncvartable2" | column -t
}
ncglobal() { # show just the global attributes
  [ $# -ne 1 ] && echo "Usage: ncglobal FILE" && return 1
  command ncdump -h "$@" | grep -A100 ^// | less
}
ncinfo() { # only get text between variables: and linebreak before global attributes
  # command ncdump -h "$1" | sed '/^$/q' | sed '1,1d;$d' | less # trims first and last lines; do not need these
  [ $# -ne 1 ] && echo "Usage: ncinfo FILE" && return 1
  ! [ -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  command ncdump -h "$1" | sed '1,1d;$d' | less # trims first and last lines; do not need these
}
ncvars() { # the space makes sure it isn't another variable that has trailing-substring
  # identical to this variable, -A prints TRAILING lines starting from FIRST match,
  # -B means prinx x PRECEDING lines starting from LAST match
  [ $# -ne 1 ] && echo "Usage: ncvars FILE" && return 1
  ! [ -r "$1" ] && echo "Error: File \"$1\" not found." && return 1
  command ncdump -h "$1" | grep -A100 "^variables:$" | sed '/^$/q' | \
    sed $'s/^\t//g' | grep -v "^$" | grep -v "^variables:$" | less
}
ncdims() {
  [ $# -ne 1 ] && echo "Usage: ncdims FILE" && return 1
  ! [ -r "$1" ] && echo "Error: File \"$1\" not found." && return 1
  command ncdump -h "$1" | sed -n '/dimensions:/,$p' | sed '/variables:/q'  | sed '1d;$d' \
      | tr -d ';' | tr -s ' ' | column -t
}

# Listing stuff
ncin() { # simply test membership; exit code zero means variable exists, exit code 1 means it doesn't
  [ $# -ne 2 ] && echo "Usage: ncin VAR FILE" && return 1
  ! [ -r "$2" ] && echo "Error: File \"$2\" not found." && return 1
  command ncdump -h "$2" | sed -n '/dimensions:/,$p' | sed '/variables:/q' \
    | cut -d'=' -f1 -s | xargs | tr ' ' '\n' | grep -v '[{}]' | grep "$1" &>/dev/null
}
nclist() { # only get text between variables: and linebreak before global attributes
  # note variables don't always have dimensions! (i.e. constants)
  # in this case looks like " double var ;" instead of " double var(x,y) ;"
  [ $# -ne 1 ] && echo "Usage: nclist FILE" && return 1
  ! [ -r "$1" ] && echo "Error: File \"$1\" not found." && return 1
  command ncdump -h "$1" | sed -n '/variables:/,$p' | sed '/^$/q' | grep -v '[:=]' \
    | cut -d';' -f1 | cut -d'(' -f1 | sed 's/ *$//g;s/.* //g' | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
}
ncdimlist() { # get list of dimensions
  [ $# -ne 1 ] && echo "Usage: ncdimlist FILE" && return 1
  ! [ -r "$1" ] && echo "Error: File \"$1\" not found." && return 1
  command ncdump -h "$1" | sed -n '/dimensions:/,$p' | sed '/variables:/q' \
    | cut -d'=' -f1 -s | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
}
ncvarlist() { # only get text between variables: and linebreak before global attributes
  local list dmnlist varlist
  [ $# -ne 1 ] && echo "Usage: ncvarlist FILE" && return 1
  ! [ -r "$1" ] && echo "Error: File \"$1\" not found." && return 1
  list=($(nclist "$1"))
  dmnlist=($(ncdimlist "$1"))
  for item in "${list[@]}"; do
    if [[ ! " ${dmnlist[@]} " =~ " $item " ]]; then
      varlist+=("$item")
    fi
  done
  echo "${varlist[@]}" | tr -s ' ' '\n' | grep -v '[{}]' | sort # print results
}

# Inquiries about specific variables
ncvarinfo() { # as above but just for one variable
  [ $# -ne 2 ] && echo "Usage: ncvarinfo VAR FILE" && return 1
  ! [ -r "$2" ] && echo "Error: File \"$2\" not found." && return 1
  command ncdump -h "$2" | grep -A100 "[[:space:]]$1(" | grep -B100 "[[:space:]]$1:" | sed "s/$1://g" | sed $'s/^\t//g'
  # the space makes sure it isn't another variable that has trailing-substring
  # identical to this variable; and the $'' is how to insert literal tab
}
ncvardump() { # dump variable contents (first argument) from file (second argument)
  [ $# -ne 2 ] && echo "Usage: ncvardump VAR FILE" && return 1
  ! [ -r "$2" ] && echo "Error: File \"$2\" not found." && return 1
  $_macos && _reverse="gtac" || _reverse="tac"
  # command ncdump -v "$1" "$2" | grep -A100 "^data:" | tail -n +3 | $_reverse | tail -n +2 | $_reverse
  command ncdump -v "$1" "$2" | $_reverse | egrep -m 1 -B100 "[[:space:]]$1[[:space:]]" | sed '1,1d' | $_reverse
  # tail -r reverses stuff, then can grep to get the 1st match and use the before flag to print stuff
  # before (need extended grep to get the coordinate name), then trim the first line (curly brace) and reverse
}
ncvartable() { # parses the CDO parameter table; ncvarinfo replaces this
  # Below procedure is ideal for "sanity checks" of data; just test one
  # timestep slice at every level; the tr -s ' ' trims multiple whitespace
  # to single and the column command re-aligns columns
  [ $# -ne 2 ] && echo "Usage: ncvartable VAR FILE" && return 1
  ! [ -r "$2" ] && echo "Error: File \"$2\" not found." && return 1
  local args=("$@")
  local args=(${args[@]:2}) # extra arguments
  cdo -s infon ${args[@]} -seltimestep,1 -selname,"$1" "$2" | tr -s ' ' | cut -d ' ' -f 6,8,10-12 | column -t 2>&1 | less
}
ncvartable2() { # as above but show everything
  [ $# -ne 2 ] && echo "Usage: ncvartable2 VAR FILE" && return 1
  ! [ -r "$2" ] && echo "Error: File \"$2\" not found." && return 1
  local args=("$@")
  local args=(${args[@]:2}) # extra arguments
  cdo -s infon ${args[@]} -seltimestep,1 -selname,"$1" "$2" 2>&1 | less
}

#-----------------------------------------------------------------------------#
# Aliases
#-----------------------------------------------------------------------------#
# CU Boulder Web
alias storm='ssh ribr5703@storm.colorado.edu'
# CU Boulder Summmit
alias summit='ssh ribr5703@login.rc.colorado.edu'

# NCAR Cheyenne
alias cheyenne='ssh -X -t rbrady@cheyenne.ucar.edu'

# LANL Institutional Computing
alias lanl='ssh -X -t rileybrady@wtrw.lanl.gov'
alias grizzly='ssh -X -t rileybrady@wtrw.lanl.gov ssh gr-fe'
alias wolf='ssh -X -t rileybrady@wtrw.lanl.gov ssh wf-fe'
alias jupyter-grizzly='ssh -X -t -L 8888:localhost:2452 rileybrady@wtrw.lanl.gov ssh -L 2452:localhost:8888 gr-fe1'

# NERSC/CORI
alias cori='ssh -X -t bradyrx@cori.nersc.gov'

# Cellar
alias cellar='ssh ribr5703@cellar.int.colorado.edu'

# # Software
alias matlab='MATLAB -nodesktop -nosplash'

# # Assorted commands
alias filecount='ls | wc -l'

# PBS Job Scheduler (e.g. Cheyenne)
# interactive job
alias qi='qsub -I -l select=1:ncpus=1 -l walltime=10800 -A P93300670 -q share'
# see your jobs
alias qq='qstat -u ${USER}'
# job history
alias qh='qhist -u ${USER}'

# Slurm Job Scheduler (e.g. LANL IC)
# interactive job
alias sinteractive='salloc --time=04:00:00 --qos=interactive'
# see your jobs
alias sq='squeue -u ${USER}'
# check what jobs are running on system
alias srunning='squeue -l | grep " RUNNING" | more'
# check what jobs are idle on system
alias sidle='squeue -l | grep -v " RUNNING" | more'
# check approximate start time for your jobs
alias sstart='squeue --start -u ${USER}'
# Get full name of jobs that are running
alias sname='sacct --format="JobID,JobName%60"'

# Weather!
alias weather='curl wttr.in'

# Other
alias cl='clear'

