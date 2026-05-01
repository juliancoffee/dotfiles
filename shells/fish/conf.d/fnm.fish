if test -x "$HOME/.local/share/fnm/fnm"
    set -gx PATH "$HOME/.local/share/fnm" $PATH
    "$HOME/.local/share/fnm/fnm" env --shell fish | source
end
