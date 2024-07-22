#!/usr/bin/env python3
from __future__ import annotations

from typing import Optional

from enum import StrEnum, Enum
from pathlib import PurePath, Path
import sys
import fnmatch
import itertools
import argparse


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

def handle_existence(desc: str, dest: Path) -> bool:
    if dest.exists():
        print(f"{desc}: skipped (already there)")
        if OPTIONS.verbose >= 1:
            if dest.is_symlink():
                print_warn(
                        "\texplanation:"
                        f" destination is taken by [symlink to {dest.resolve()}]"
                )
            else:
                print_warn(f"\texplanation: destination is taken by non-symlink")

        if OPTIONS.verbose >= 1:
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
                        "\tnote: it's a [directory with {} files, {} dirs, {} links]"
                            .format(file_num, dir_num, link_num)
                )
        return True
    return False

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

def setup_link(desc: str, src: Path, dest: Path) -> None:
    if handle_existence(desc, dest):
        return

    dest.symlink_to(src)
    print_ok(f"{desc}: {dest} => {src}")

# - name
# - either direct source in dotfiles or a list of alternatives
# - link destination
SetupRequest = tuple[str, Path | list[tuple[str, Path]], Path]

def setup(req: SetupRequest) -> None:
    desc, src, dest = req
    if handle_existence(desc, dest):
        return

    if isinstance(src, Path):
        setup_link(desc, src, dest)
    elif isinstance(src, list):
        choice, src = make_choice(desc, src)
        setup_link(f"desc/{choice}", src, dest)
    else:
        raise TypeError(f"wrong `src` type: {src}")


class FsNode:
    def __init__(self, this: Path, *, prev: Optional[FsNode]) -> None:
        self._this = this.absolute()
        self.prev = prev

        self.next: Optional[list[FsNode]] = None
        if this.is_dir():
            self.next = []

    def current(self) -> Path:
        return self._this

    def find_adopter(self, potential_child: Path) -> Optional[FsNode]:
        """ Finds the node that would be a direct parent in the tree """
        potential_child = potential_child.absolute()

        def find_direct_parent(tree: FsNode, path: Path) -> Optional[FsNode]:
            if not path.is_relative_to(tree.current()):
                return None
            if tree.next is None:
                return None

            found = None
            for child in tree.next:
                attempt = find_direct_parent(child, path)
                if attempt is not None:
                    found = attempt
                    break

            # If none of the candidates qualify, but we do, we are the parent
            if found is None:
                return tree
            else:
                return found

        return find_direct_parent(self, potential_child)

    def try_adopting(self, child: Path) -> bool:
        """ Pull the child under the tree.

        Creates new node and puts it to the direct parent.
        """
        adopter = self.find_adopter(child)
        if adopter is None:
            return False

        assert adopter._push_child(child), "adopter should be able to have"
        return True

    def nuke_ancestory(self) -> list[FsNode]:
        """ Nuke the ancestory of this node.

        Returns the list of orphaned branches.
        """
        leftout = []
        cursor = self
        while cursor.prev is not None:
            assert cursor.prev.next is not None, ".prev always has .next"

            children = filter(lambda x: x is not cursor, cursor.prev.next)
            for branch in children:
                branch.prev = None
                leftout.append(branch)
            cursor = cursor.prev

        return leftout

    def _push_child(self, child: Path) -> bool:
        """ Register new child node

        Returns `False` if the current node can't have children, probably
        because it's a file.
        """
        new_child = FsNode(child, prev=self)
        if self.next is not None:
            self.next.append(new_child)
            return True
        return False


class DirState(Enum):
    # All content of a directory is under config
    HOLDER = 1
    # Some of content of a directory is under config
    DIRTY = 2
    # We don't know
    UNKNOWN = 3

def check_missed(configs: list[SetupRequest], dotfiles: Path) -> list[FsNode]:
    taken = []
    for _desc, src, _dest  in configs:
        if isinstance(src, Path):
            taken.append(src.name)
        elif isinstance(src, list):
            for _desc_a, alternative in src:
                taken.append(alternative.name)

    potentially_missed: list[FsNode] = []
    for root, dirs, files in dotfiles.walk():
        skiplist = [
            fnmatch.filter(dirs, skippath)
            for skippath in [".git", ".mypy_cache", "blog", "scripts"]
        ]

        for d in itertools.chain.from_iterable(skiplist):
            dirs.remove(d)

        # default to unknown
        state = DirState.UNKNOWN

        # find dirs that already under config and remove them from the
        # algorithm
        taken_dirs = [d for d in dirs if d in taken]
        for d in taken_dirs:
            dirs.remove(d)

        # analyze the files
        taken_files = [file for file in files if file in taken]
        left_files = [file for file in files if file not in taken]

        if (taken_dirs or taken_files) and not (dirs or left_files):
            state = DirState.HOLDER

        if (taken_dirs or taken_files) and (dirs or left_files):
            state = DirState.DIRTY

        def register_miss(path, potentially_missed):
            for miss in potentially_missed:
                if miss.try_adopting(path):
                    break
            else:
                unknown = FsNode(path, prev=None)
                potentially_missed.append(unknown)

        def cleanup_from(path, potentially_missed):
            orphans = None
            catch = None
            for miss in potentially_missed:
                adopter = miss.find_adopter(path)
                if adopter is not None:
                    orphans = adopter.nuke_ancestory()
                    catch = miss
                    break

            if catch is not None:
                potentially_missed.remove(catch)

        # If unknown, just add to potentially_missed
        if state is DirState.UNKNOWN:
            register_miss(root, potentially_missed)
        # If completely taken, remove ancestors from potentially_missed
        elif state is DirState.HOLDER:
            cleanup_from(root, potentially_missed)
        # If dirty, do that too, but also handle missed files.
        elif state is DirState.DIRTY:
            cleanup_from(root, potentially_missed)
            # no need to do the same with dirs, btw
            for missed_file in left_files:
                register_miss(missed_file, potentially_missed)

    return potentially_missed

def dotfiles_dir() -> Path:
    if OPTIONS.verbose >= 1:
        print_warn("warning: assuming current directory as the dotfiles root")
    return Path.cwd()

def setup_all(configs: list[SetupRequest]) -> None:
    print_ok("Setting links up...")
    for config in configs:
        setup(config)

def display_missed(configs: list[SetupRequest], dotfiles: Path) -> None:
    print_ok("Checking paths that aren't in the config...")
    miss = False
    for missed in check_missed(configs, dotfiles):
        miss = True
        print(f"\t{missed.current()}")
    if not miss:
        print_ok("you're good!")

def options() -> argparse.Namespace:
    # cmdline parsing
    prog = sys.argv[0]
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=
        "=" * 50 +
            "\nThis program will help you to manage your dotfiles."
            "\n\n"
            "\"The most straightforward argument is probably `link-all`."
            "\nExample if you want to link everything:"
            f"\n\t{prog} --link-all"
            "\n"
        + "=" * 50)

    parser.add_argument(
            "-a", "--link-all",
            help="link all dotfiles in the config",
            action="store_true"
    )
    parser.add_argument(
            "--check",
            help="compare the dotfiles with config and display which are missed",
            action="store_true")
    parser.add_argument(
            "-v", "--verbose",
            help="be verbose (can be repeated up to -vv)",
            default=0,
            action="count"
    )
    # force-feed help when no arguments were supplied
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)
    return parser.parse_args()
OPTIONS = options()

def main():
    # setup
    home = Path.home()
    dotfiles = dotfiles_dir()

    configs = [
        # tmux config is old, it lives in $HOME
        ("tmux", dotfiles / "tmux/.tmux.conf", home / ".tmux.conf"),
        # zsh too
        ("zsh", dotfiles / "shells/zsh/zshrc", home / ".zshrc"),
        # mpv is a good boi
        ("mpv", dotfiles / "other/mpv", home / ".config/mpv"),
        # all others too
        ("nvim", dotfiles / "editors/nvim", home / ".config/nvim"),
        (
            "alacritty",
            [
                # runs zsh and starts tmux
                ("mac", dotfiles / "terminals/alacritty-mac"),
            ],
            home / ".config/alacritty",

        ),
    ]

    # command execution
    if OPTIONS.check:
        display_missed(configs, dotfiles)

    if OPTIONS.link_all:
        setup_all(configs)

if __name__ == "__main__":
    main()
