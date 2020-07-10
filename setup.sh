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

    # check if link exists
    if [ -L "$dest" ]
    then
        if [ -e "$dest" ]
        then
            warn_color
            echo "$name : symbolic link already set"
            reset_color

            return
        else
            error_color
            echo "$name : symbolic link set, but broken"
            reset_color

            return
        fi
    fi

    # check if destination already exists
    if [ -e "$dest" ] 
    then
        error_color
        echo "$name : config exists: skip"
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
path_to_dots=$(dirname "$0")
if test "$path_to_dots" -ef "$DOTS"
then
    echo "===== Dotfiles root in $DOTS ====="
    setup "$DOTS/editors/nvim" "$HOME/.config/nvim" "Neovim"
    setup "$DOTS/wm/i3" "$HOME/.config/i3" "i3"
    setup "$DOTS/pagers/most/.mostrc" "$HOME/.mostrc" "most"
    setup "$DOTS/other/rofi" "$HOME/.config/rofi" "rofi"
else
    error_color
    echo "Script runned from $path_to_dots, but \$DOTS set to $DOTS"
    reset_color
fi
