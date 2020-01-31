#
# fish config
#

#update
alias upd="source $HOME/.config/fish/config.fish"

#dotfiles
set -g DOTFILES "$HOME/dotfiles"
function todot
    cp $argv[1] $DOTFILES/.
end

#plugins and other
set PATH $PATH $HOME/repos/v/bin
set PATH $PATH $HOME/.cargo/bin
set PATH $PATH $HOME/repos/ion/target/release

#some variables
set -l editor "nvim"
set -l TMUX_rc "$HOME/.tmux.conf.local"
set -l SHELL_rc "$HOME/.config/fish/config.fish"
set -l WM_rc "$HOME/.config/awesome/rc.lua"
set -l THEME_rc "$HOME/.config/awesome/theme.lua"

set -l NVIM_rc "$HOME/.config/nvim/init.vim"
set -l EMACS_rc "$HOME/.emacs.d/init.el"

#Alias for edit configs
# Shell
alias edsh="$editor $SHELL_rc" # fish
# Editors
alias edvim="$editor $NVIM_rc" # nvim
alias edem="$editor $EMACS_rc" # emacs
# Window managers
alias edwm="$editor $WM_rc" # awesome wm
alias edtheme="$editor $THEME_rc" # theme
# Terminals
alias edterm="$editor $HOME/.config/alacritty/alacritty.yml"
# Terminal multiplexor
alias edtm="$editor $TMUX_rc"
alias edhello="cd $HOME/Workspace/scripts/tmux"


#some ls aliases
alias la="ls -a"
alias ll="ls -l"

#Alias for default command
alias ls='ls --color=auto --sort=extension --group-directories-first'
alias grep='grep --color=auto'
alias lynx="lynx -vikeys"
alias emacs="emacs -nw"
alias htop="htop -t"
alias csc="chicken-csc"
alias objdump="objdump -M intel"

#prompt
set -U fish_prompt_pwd_dir_length 0

#Functions and aliases for change directory
set -U STORAGE "$HOME/Storage"
set -U WORK "$HOME/Workspace"
set -U CONFIG "$HOME/.config"
set -U DOWNLOADS "$HOME/Downloads"

function store
    cd "$STORAGE/$argv[1]"
end
complete -c store -x -a "(__fish_complete_directories ($STORAGE))" 

function cdwork 
    cd "$WORK/$argv[1]"
end
complete -c store -x -a "(__fish_complete_directories ($WORK))" 

function cdconf 
    cd "$CONFIG/$argv[1]"
end
complete -c cdconf -x -a "(__fish_complete_directories ($CONFIG))" 

function cdload
    cd "$DOWNLOADS/$argv[1]"
end
complete -c cdload -x -a "(__fish_complete_directories ($DOWNLOADS))" 


#tmux
function start 
    $HOME/Workspace/scripts/tmux/scripts/start.py
end
function port 
    $HOME/Workspace/scripts/tmux/scripts/second.py
end
function hello 
    $HOME/Workspace/scripts/tmux/scripts/hello.py
end
