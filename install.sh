if [ -e "$HOME/.config/nvim" ] 
then
    echo "nvim config exists: pass"
    echo "do smth about that"
else
    ln -s "$HOME/dotfiles/editors/nvim" "$HOME/.config/nvim"
fi
