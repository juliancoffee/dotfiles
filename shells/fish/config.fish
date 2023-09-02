#
# fish config
#

#update
alias upd="source $HOME/.config/fish/config.fish"

function fish_greeting
    cal
end

function fish_command_not_found
    __fish_default_command_not_found_handler $argv[1]
end

#export variables
export TERM=kitty
export EDITOR=nvim
export MANPAGER=most

#plugins and other
export PYENV_ROOT="$HOME/.local/share/pyenv"

set PATH $PATH $WORK/bin
set PATH $PATH $HOME/.poetry/bin
set PATH $PATH $HOME/.cargo/bin
set PATH $PATH $HOME/.opam/default/bin
set PATH $PATH $HOME/.local/bin
set PATH $PATH $HOME/.yarn/bin
set PATH $PATH $HOME/.gem/ruby/2.7.0/bin
set PATH $PATH $PYENV_ROOT/bin
set PATH $PATH $HOME/.pub-cache/bin
set PATH $PATH $HOME/.nix-profile/bin

#some local variables
set -l TMUX_rc "$HOME/.tmux.conf"
set -l SHELL_rc "$HOME/.config/fish/config.fish"
set -l WM_rc "$HOME/.config/i3/config"

set -l NVIM_rc "$HOME/.config/nvim/init.lua"

#Alias for edit configs
# Shell
abbr --add edsh "$EDITOR $SHELL_rc" # fish
# Editors
abbr --add edvim "$EDITOR $NVIM_rc" # nvim
# Window managers
alias edwm="$EDITOR $WM_rc" # wm
# Terminals
alias edterm="$EDITOR $HOME/.config/alacritty/alacritty.yml"
# Terminal multiplexor
alias edtm="$EDITOR $TMUX_rc"

#some ls aliases
alias la="ls -a"
alias ll="ls -l"

#nvim aliases
abbr --add novim "nvim -u NORC"

#Alias for default command
alias tree='tree -C'
alias ls='ls --color=auto --sort=extension --group-directories-first'
alias grep='grep --color=auto'
alias lynx="lynx -vikeys"
#alias emacs="emacs -nw"
alias htop="htop -t"
alias csc="chicken-csc"
#alias time="time --portability"
alias objdump="objdump -M intel"
alias activate="source venv/bin/activate.fish"

#prompt
set -U fish_prompt_pwd_dir_length 0

#Functions and aliases for change directory
set -U STORAGE "$HOME/Storage"
set -U WORK "$HOME/Workspace"
set -U CONFIG "$HOME/.config"
set -U DOWNLOADS "$HOME/Downloads"

function toterm
    sh -c "cat $argv[1] | nc termbin.com 9999 | xclip -selection clipboard"
end

function store
    cd "$STORAGE/$argv[1]"
end
complete -c store -x -a "(__fish_complete_directories ($STORAGE))" 

function cdwork 
    cd "$WORK/$argv[1]"
end
complete -c cdwork -x -a "(__fish_complete_directories ($WORK))" 

function cdconf 
    cd "$CONFIG/$argv[1]"
end
complete -c cdconf -x -a "(__fish_complete_directories ($CONFIG))" 

function cdload
    cd "$DOWNLOADS/$argv[1]"
end
complete -c cdload -x -a "(__fish_complete_directories ($DOWNLOADS))" 

#dotfiles
set -U DOTFILES "$HOME/.config/dotfiles"
function todot
    cp $argv[1] $DOTFILES/.
end
function cddot
    cd "$DOTFILES/$argv[1]"
end
complete -c cddot -x -a "(__fish_complete_directories ($DOTFILES))" 

#pyenv
if command -v pyenv 1>/dev/null 2>&1
    pyenv init - | source
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
#eval /home/julian/anaconda3/bin/conda "shell.fish" "hook" $argv | source
# <<< conda initialize <<<

export GOPATH=$HOME/go
eval (opam config env)
export JAVA_HOME=/usr/lib/jvm/default
