# Hi!
I'm a Neovim user and I like it quite a lot. As you may or may not know, Neovim is the successor to Vim editor, the [editor] you open and can't quit.

And in July of 2021, the new 0.5 release of Neovim introduced a lot of stuff, except I managed to miss it all.
The goal of this writing isn't to convince you to use Vim or Neovim, nor to tell you the story about the history of different \*vi\* editors because, honestly, I don't know it myself.
The goal for me is to finally start the journey of new features that Neovim now provides and share them with you.

This story will be split into multiple parts and the first part will be about absolute essentials, how to take your old Vim config and turn it into a modern, 2023-style Neovim config.

# Start
Warn you, I'm a somewhat extreme minimalist, so don't expect anything crazy. The real advantage of post-0.5 Neovim will be covered next, but we need to start somewhere.
Let's get to the code!
```bash
$ nvim
```
![image](https://github.com/juliancoffee/dotfiles/assets/42647349/703e406e-f5ee-4649-a893-2bb71cc94562)

This is probably what you will get when you open neovim for the first time.
And if that's your first time, I advise you to type `:help` to see the manual, or even better, type `:Tutor` to take a neat 30 interactive tutorial, which will teach you the basics of vi-style editors.
Another thing about vim, which might seem unusual is the notion of modes. Type `:help vim-modes` to learn more, but in short, you have Normal mode, which is the mode where you can start all commands and Insert mode. If you're in Normal mode and you want to start actually typing something in the document, press `i`. If you're in Insert mode and want to do something (for example, quit), type `<Esc>`.

Now, Lua.
I already have my old config in vim script, which is mostly based on `coc.nvim` and `vim-plug`, I tried `ale`, `deoplete` and who knows what else. Let's get rid of all of this, because we can do better.
There are two ways to proceed:
 - Incrementally add Lua to your `init.vim` using heredoc, `:help lua-heredoc`
 - Move your init.vim somewhere and create `init.lua` in the same folder.

I went with moving the whole nvim directory in my dotfiles and creating a fresh one with `init.lua`.

# Options
```vim
set termguicolors
set completeopt-=preview
set number             "numbers
set relativenumber
set tabstop=4   
set shiftwidth=4
set smarttab         "tabs
set expandtab
set smartindent
set exrc             " local config
set tabpagemax=500   " why this limit even exists?
```
One of the reasons I wanted to start from scratch is because I truly don't know what I have in config and why I have it. So, let's pick what we actually need.
There are two ways to set options in Lua, using `vim.o` global or `vim.opt`. For the most part, there is no difference between them, but `vim.opt` provides a more user-friendly API for complex things, like `listchars`. `vim.o` is much stupider than that as far as I can tell, and it's shorter to type, so that's what I will use.

Read `:help lua-guide` for more.

```lua
vim.o.termguicolros = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.tabpagemax = 500
```

And, to make it less painful to look at, you can set a colour scheme. It seems that all default colour schemes were written at the time when GUI colours weren't a thing, so you'll still probably want a third-party colour scheme later, but `habamax` and `desert` look decent. You can set colour scheme almost the same way you do it in vim, via command. To call a command, you can use `vim.cmd` function.
```lua
vim.cmd.colorscheme('desert')
```
And yes, I see the typo in `vim.o.termguicolros`. For some reason, neovim screams about that when you do `:source %`, (`%` expands to the current buffer, which in this case is your `init.lua`), but not when you just open your editor. Remind me to create or look for an issue about that :).

[editor]: https://stackoverflow.com/questions/11828270/how-do-i-exit-vim
