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

def setup_link(desc: str, src: Path, dest: Path) -> None:
    try:
        dest.symlink_to(src)
        print_ok(f"{desc}: {dest} => {src}")
    except FileExistsError as e:
        print_warn(
                f"{desc}: failed to create the symlink, it probably already exists"
        )
        print_warn(str(e))

def main():
    home = Path.home()
    print_warn("Assuming current directory as the dotfiles root")
    dotfiles = Path.cwd()

    simple_configs = [
        # tmux config is old, it lives in $HOME
        ("tmux", dotfiles / "tmux/.tmux.conf", home / ".tmux.conf"),
        # zsh too
        ("zsh", dotfiles / "shells/zsh/zshrc", home / ".zshrc"),
    ]

    option_configs = [
        ("alacritty-zsh")
    ]

    for (desc, src, dest) in simple_configs:
        setup_link(desc, src, dest)

main()
