#
# fish config
#

#update
alias upd="source $HOME/.config/fish/config.fish"

function fish_greeting
    cal
end

function fish_prompt
    larta
end

#export variables
export TERM=kitty
export EDITOR=nvim
export MANPAGER=most

#plugins and other
export PYENV_ROOT="$HOME/.local/share/pyenv"
export ORACLE_HOME="/usr/lib/oracle/product/11.2.0/xe"
export ORACLE_SID="XE"

set PATH $PATH $WORK/bin
set PATH $PATH $HOME/.poetry/bin
set PATH $PATH $ORACLE_HOME/bin
set PATH $PATH $HOME/repos/v/bin
set PATH $PATH $HOME/.cargo/bin
set PATH $PATH $HOME/.opam/default/bin
set PATH $PATH $HOME/repos/ion/target/release
set PATH $PATH $HOME/.local/bin
set PATH $PATH $HOME/.yarn/bin
set PATH $PATH $HOME/.gem/ruby/2.7.0/bin
set PATH $PATH $PYENV_ROOT/bin
set PATH $PATH $HOME/.pub-cache/bin
set PATH $PATH $HOME/.nix-profile/bin
set PATH $PATH $HOME/.emacs.d/bin

#some variables
set -l TMUX_rc "$HOME/.tmux.conf"
set -l SHELL_rc "$HOME/.config/fish/config.fish"
set -l WM_rc "$HOME/.config/i3/config"
set -l THEME_rc "$HOME/.config/awesome/theme.lua"

set -l NVIM_rc "$HOME/.config/nvim/init.vim"
set -l EMACS_rc "$HOME/.emacs.d/init.el"

#Alias for edit configs
# Shell
abbr --add edsh "$EDITOR $SHELL_rc" # fish
# Editors
abbr --add edvim "$EDITOR $NVIM_rc" # nvim
alias edem="$EDITOR $EMACS_rc" # emacs
# Window managers
alias edwm="$EDITOR $WM_rc" # awesome wm
alias edtheme="$EDITOR $THEME_rc" # theme
# Terminals
alias edterm="$EDITOR $HOME/.config/alacritty/alacritty.yml"
# Terminal multiplexor
alias edtm="$EDITOR $TMUX_rc"
alias edhello="cd $HOME/Workspace/scripts/tmux"


#some ls aliases
alias la="ls -a"
alias ll="ls -l"

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

function ed
    if $argv[2]
        echo "Wow"
    else if test -d $argv[1] 
        cd argv[1]
    else if test -f $argv[1]
        echo $argv[1] is a file
    else 
        echo $argv[1] "doesn't" exists
    end
end

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

function cdtest
    cdwork "test/$argv[1]"
end
complete -c cdtest -x -a "(__fish_complete_directories ($WORK/test))" 

function cdcode
    cdwork "codewars/$argv[1]"
end
complete -c cdcode -x -a "(__fish_complete_directories ($WORK/codewars))" 

function cdconf 
    cd "$CONFIG/$argv[1]"
end
complete -c cdconf -x -a "(__fish_complete_directories ($CONFIG))" 

function cdload
    cd "$DOWNLOADS/$argv[1]"
end
complete -c cdload -x -a "(__fish_complete_directories ($DOWNLOADS))" 


#git
abbr --add g "git"
abbr --add gs "git status"
abbr --add gall "git add -A"
abbr --add gc "git commit"

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

#dotfiles
set -U DOTFILES "$HOME/dotfiles"
function todot
    cp $argv[1] $DOTFILES/.
end
function cddot
    cd "$DOTFILES/$argv[1]"
end

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
