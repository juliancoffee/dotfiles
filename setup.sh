#!/usr/bin/env sh

if [ -e "$HOME/.config/nvim" ] 
then
    echo "nvim config exists: pass"
    echo "do smth about that"
else
    ln -s "$HOME/dotfiles/editors/nvim" "$HOME/.config/nvim"
    echo "nvim config set up"
fi

if [ -e "$HOME/.config/i3" ] 
then
    echo "i3 config exists: pass"
    echo "do smth about that"
else
    ln -s "$HOME/dotfiles/wm/i3" "$HOME/.config/i3"
    echo "i3 config set up"
fi
