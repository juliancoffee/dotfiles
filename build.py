#!/usr/bin/env python3

from enum import StrEnum
from pathlib import PurePath, Path

class ColorCode(StrEnum):
    """ To be used with `print_colored`.
    Read `print_colored` to understand what these numbers mean, if you want.
    """
    RED = "31"
    YELLOW = "33"
    GREEN = "32"


def print_colored(msg: str, code: ColorCode) -> None:
    # ANSI escape codes terminal magic
    #
    # when you output the following series of characters
    # \x1b[<some code here>m
    #
    # your terminal will act, changing the colour of characters to follow,
    # their position, their style, etc.
    #
    # For example,
    # "\x1b[31m" means everything after that must be red, the "command" itself
    # vanishes, of course.
    #
    # \x1b just means 27 in hex, ESCAPE in ASCII, [31m are just regular
    # characters
    #
    # Note, "everything" really means "everything", try open some boring
    # shell (`sh` should do the trick) without neatly customized colored
    # prompt and type there:
    # ```sh
    # $ echo "\x1b[31m"
    # ```
    # and every character you'll see after that will be red, including prompts,
    # your own typed in commands, their results, everything.
    #
    # To "counter" that, you must reset the colour, after writing the message,
    # type, \x1b[0m, another escape code.
    #
    # off-topic, thanks Guido for making print() adding \n by default.
    print(f"\x1b[{code}m{msg}\x1b[0m")

def print_ok(msg: str) -> None:
    print_colored(msg, ColorCode.GREEN)

def print_warn(msg: str) -> None:
    print_colored(msg, ColorCode.YELLOW)

def print_err(msg: str) -> None:
    print_colored(msg, ColorCode.RED)

def make_choice(desc: str, choices: list[tuple[str, Path]]) -> tuple[str, Path]:
    print(f"There are multiple choices for {desc}:")
    for (i, (desc, path)) in enumerate(choices):
        print(f"{i}) {desc} <> {path}")

    while True:
        try:
            request = input("Please type a number to pick: ")
            idx = int(request)
            return choices[idx]
        except ValueError:
            print_err("failed to parse the number, please try again")

def handle_existence(desc: str, dest: Path) -> bool:
    if dest.exists():
        print(f"{desc}:")
        if dest.is_symlink():
            print_warn(f"it's already there, it's a [symlink to {dest.resolve()}]")
        else:
            print_warn(f"it's already there")
        if dest.is_file():
            print_warn("it's a [plain file]")
        if dest.is_dir():
            file_num = 0
            dir_num = 0
            link_num = 0
            for child in dest.iterdir():
                if child.is_file():
                    file_num += 1
                if child.is_dir():
                    dir_num += 1
                if child.is_symlink():
                    link_num += 1

            print_warn(
                    f"it's a [directory with "
                    f"{file_num} files, "
                    f"{dir_num} dirs, "
                    f"{link_num} links]"
            )
        print_warn("skipping")
        return True
    return False

def setup_link(desc: str, src: Path, dest: Path) -> None:
    if handle_existence(desc, dest):
        return

    dest.symlink_to(src)
    print_ok(f"{desc}: {dest} => {src}")

def main():
    home = Path.home()
    print("Assuming current directory as the dotfiles root")
    dotfiles = Path.cwd()

    simple_configs = [
        # tmux config is old, it lives in $HOME
        ("tmux", dotfiles / "tmux/.tmux.conf", home / ".tmux.conf"),
        # zsh too
        ("zsh", dotfiles / "shells/zsh/zshrc", home / ".zshrc"),
        # mpv is a good boi
        ("mpv", dotfiles / "other/mpv", home / ".config/mpv"),
        ("nvim", dotfiles / "editors/nvim", home / ".config/nvim"),
    ]

    option_configs = [
        # alacritty has options mainly because of shell usage
        #
        # On my Linux machines (with i3wm, at least) I just make a keybind to
        # run alacritty with tmux, plus I use fish.
        #
        # On MacOS, I can't (or don't know how) edit what button on by bar does
        # so instead, I specify how the shell should be invoked in the config,
        # which also runs tmux, but also zsh.
        (
            "alacritty",
            [
                ("mac", dotfiles / "terminals/alacritty-mac"),
            ],
            home / ".config/alacritty",

        ),
    ]

    for (desc, src, dest) in simple_configs:
        setup_link(desc, src, dest)

    for (desc, choices, dest) in option_configs:
        if handle_existence(desc, dest):
            continue
        choice, src = make_choice(desc, choices)
        setup_link(f"desc/{choice}", src, dest)

main()
