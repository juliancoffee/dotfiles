### About
It is my repo for my dotfiles.<br>
Clone it to ~/.config/dotfiles and edit config.py main() function

### Currently available
Check config.py

### Setup
There is a file config.py, run it as `./config.py` and follow the instructions

### Zsh maintenance
Zsh startup is optimized with a compiled grml config, a compiled completion dump,
and `compinit -C`. If completion state ever gets stale after editing completion
files, rebuild it manually.

Compile the stable Zsh files:

```zsh
zcompile ~/.zsh/grml.zsh
zcompile ~/.config/zsh/.zcompdump
```

If completions look stale, recreate the dump and recompile it:

```zsh
rm -f ~/.config/zsh/.zcompdump ~/.config/zsh/.zcompdump.zwc
zsh -fc 'autoload -Uz compinit; compinit -d ~/.config/zsh/.zcompdump; zcompile ~/.config/zsh/.zcompdump'
```
