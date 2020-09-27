#!/usr/bin/env sh

# Dependencies:
# POSIX shell (bash in sh emulation, for example can be used)
# coreutils:
#   printf
#   realpath
#   dirname

error_color() {
    printf "\x1b[31m" #red for error
}

warn_color() {
    printf "\x1b[33m"
}

ok_color() {
    printf "\x1b[32m"
}

reset_color() {
    printf "\x1b[0m"
}

debug() {
    if [ -n "$DOTS_DEBUG" ]
    then
        echo "$1"
    fi
}

setup() {
    src="$1"
    dest="$2"
    name="$3"

    # maybe we forgot to set $name
    if [ -z "$name" ]
    then
        warn_color
        echo "setup called with $src to $dest, but without $name, but we'll continue"
        echo "fix it, please"
        reset_color
    fi

    # check if arguments passed
    if [ -z "$src" ] 
    then
        error_color
        echo "$name: src is undefined, skip"
        reset_color

        return
    elif [ -z "$dest" ]
    then
        error_color
        echo "$name: destination is undefined, skip"
        reset_color

        return
    fi

    # check if link exists
    if [ -L "$dest" ]
    then
        if [ -e "$dest" ]
        then
            warn_color
            echo "$name: symbolic link already set"
            reset_color

            return
        else
            error_color
            echo "$name: symbolic link set, but broken, skip"
            reset_color

            return
        fi
    fi

    # check if destination already exists
    if [ -e "$dest" ] 
    then
        error_color
        echo "$name: config exists, skip"
        reset_color

        return
    fi

    # do set up
    if ln -s "$src" "$dest"
    then
        ok_color
        echo "$name : config set up from $src to $dest"
        reset_color
    else
        error_color
        echo "$name : something went wrong with setting config"
        reset_color
    fi
}

# set DOTFILES to default value if unset
debug "${DOTFILES="$HOME/.config/dotfiles"}"
called_with=$(dirname "$0")            # get relative path
called_from=$(realpath "$called_with") # convert to absolute
if [ "$called_from" = "$DOTFILES" ]
then
    # Checking variables
    #
    # For firefox, we may automaticaly guess profile directory, but there may
    # be more than one so just set FIREFOX_PROFILE_PATH yourself
    # Enter about:profiles in firefox to see needed directory
    #firefox_err_msg="
    #    Path to firefox profile must be specified
    #    Read comments in setup.sh to fix it
    #"
    #${FIREFOX_PROFILE_PATH?"$(error_color)$firefox_err_msg$(reset_color)"}

    # Run setup
    echo "===== Dotfiles root in $DOTFILES ====="
    setup "$DOTFILES/editors/nvim" "$HOME/.config/nvim" "Neovim"
    setup "$DOTFILES/wm/i3" "$HOME/.config/i3" "i3"
    setup "$DOTFILES/pagers/most/.mostrc" "$HOME/.mostrc" "most"
    setup "$DOTFILES/other/rofi" "$HOME/.config/rofi" "rofi"
    #setup "$DOTFILES/browser/firefox/user.js" "$FIREFOX_PROFILE_PATH/user.js" "firefox"
    setup "$DOTFILES/shells/fish/config.fish" "$HOME/.config/fish/config.fish" "fish"
    setup "$DOTFILES/wm/bars/polybar" "$HOME/.config/polybar" "polybar"
    setup "$DOTFILES/other/mpv/mpv.conf" "$HOME/.config/mpv/mpv.conf" "mpv"
    setup "$DOTFILES/wm/compositors/picom" "$HOME/.config/picom" "picom"
else
    # Script is using default value for dotfiles path, which in my case is 
    # $HOME/dotfiles. If path where script runned don't match this value,
    # that means your dotfiles directory is in another place.
    # You should change DOTFILES variable in script above or set DOTFILES variable.
    error_color
    echo "
        Script runned from $called_from, but \$DOTFILES set to $DOTFILES.
        Read comments in setup.sh to fix it
    "
    reset_color
fi
