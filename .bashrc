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