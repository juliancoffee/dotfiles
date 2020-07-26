#!/usr/bin/env sh

# shellcheck disable=SC2039

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

setup() {
    local src="$1"
    local dest="$2"
    local name="$3"

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

DOTS="$HOME/dotfiles"
current_path_to_dots=$(dirname "$0")
if test "$current_path_to_dots" -ef "$DOTS"
then
    # Checking variables
    #
    # For firefox, we may automaticaly guess profile directory, but there may be more than one
    # so just set FIREFOX_PROFILE_PATH yourself
    # enter about:profiles in your firefox to see needed directory
    firefox_err_msg="
        path to firefox profile must be specified
        (read comments in setup.sh)
    "
    ${FIREFOX_PROFILE_PATH:?"$(error_color)$firefox_err_msg$(reset_color)"}

    # Run setup
    echo "===== Dotfiles root in $DOTS ====="
    setup "$DOTS/editors/nvim" "$HOME/.config/nvim" "Neovim"
    setup "$DOTS/wm/i3" "$HOME/.config/i3" "i3"
    setup "$DOTS/pagers/most/.mostrc" "$HOME/.mostrc" "most"
    setup "$DOTS/other/rofi" "$HOME/.config/rofi" "rofi"
    setup "$DOTS/browser/firefox/user.js" "$FIREFOX_PROFILE_PATH/user.js" "firefox"
    setup "$DOTS/shells/fish/config.fish" "$HOME/.config/fish/config.fish" "fish"
else
    # Script is using default value for dotfiles path, which in my case is 
    # $HOME/dotfiles if path where script runned don't match this value,
    # it is error
    error_color
    echo "Script runned from $current_path_to_dots, but \$DOTS set to $DOTS."
    echo "Change it in setup.sh file"
    reset_color
fi
