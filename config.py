#!/usr/bin/env python3
from __future__ import annotations

from typing import Optional, Any, Callable, Iterator, ClassVar, cast

import sqlite3

from enum import StrEnum, Enum
from pathlib import PurePath, Path
from dataclasses import dataclass
import shutil
import sys
import os
import fnmatch
import itertools
import argparse

class ColorCode(StrEnum):
    """ To be used with `print_colored`.

    Read `print_colored` docs to understand what these numbers mean, if you
    want.
    """
    RED = "31"
    YELLOW = "33"
    GREEN = "32"


def print_colored(msg: str, code: ColorCode) -> None:
    """
    ANSI escape codes terminal magic

    when you output the following series of characters
    \x1b[<some code here>m

    your terminal will act, changing the colour of characters to follow,
    their position, their style, etc.

    For example,
    "\x1b[31m" means everything after that must be red, the "command" itself
    vanishes, of course.

    \x1b just means 27 in hex, ESCAPE in ASCII, [31m are just regular
    characters

    Note, "everything" really means "everything", try open some boring
    shell (`sh` should do the trick) without neatly customized colored
    prompt and type there:
    ```sh
    $ echo "\x1b[31m"
    ```
    and every character you'll see after that will be red, including prompts,
    your own typed in commands, their results, everything.

    To "counter" that, you must reset the colour, after writing the message,
    type, \x1b[0m, another escape code.

    off-topic, thanks Guido for making print() adding \n by default.
    """
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

def load_ignore_file() -> Iterator[str]:
    src = ".configignore"
    with open(src, 'r') as f:
        for line in f:
            if line.startswith("#"):
                continue
            if not line.strip():
                continue
            yield line.rstrip()

def pretty_path(p: Path, home: Path, dotfiles: Path) -> str:
    """ Makes the path easier to read
    Replaces $HOME with `~`, and dotfiles with `{.}`
    """
    p_string = os.fspath(p)
    home_string = os.fspath(home)
    dots_string = os.fspath(dotfiles)

    return (
        p_string
            .replace(dots_string, "{.}")
            .replace(home_string, "~")
    )

class Recorder:
    def __init__(self) -> None:
        self.connection = sqlite3.connect("recorder.db", autocommit=False)
        fresh = (self
            .connection
            .execute("SELECT name FROM sqlite_master WHERE name='operation'")
            .fetchone() is None)

        if fresh:
            with self.connection as con:
                con.execute(
                """CREATE TABLE operation(
                            desc TEXT,
                            src TEXT,
                            dest TEXT
                )""")

    def register_link(self, desc: str, src: Path, dest: Path) -> None:
        src_string = os.fspath(src)
        dest_string = os.fspath(dest)
        with self.connection as con:
            con.execute(
                "INSERT INTO operation VALUES(?, ?, ?)",
                (desc, src_string, dest_string)
            )

    def unregister_link(self, dest: Path):
        dest_string = os.fspath(dest)
        with self.connection as con:
            con.execute(
                "DELETE FROM operation WHERE operation.dest = ?",
                (dest_string, )
            )

    def numbered_configs(self) -> Iterator[tuple[int, Config]]:
        res = self.connection.execute(
            "SELECT oid, desc, src, dest FROM operation"
        )
        for i, desc, src_string, dest_string in res.fetchall():
            src = Path(src_string)
            dest = Path(dest_string)
            yield i, Config(desc, src, dest)

    def registered_configs(self) -> list[Config]:
        return [c for i, c in self.numbered_configs()]

    def undo_all(self) -> None:
        configs = self.registered_configs()
        for config in configs:
            config.remove_link()

    def undo_by_oid(self, oid: int) -> None:
        res = self.connection.execute(
            "SELECT desc, src, dest FROM operation WHERE oid = ?",
            (oid, )
        )
        desc, src_string, dest_string = res.fetchone()
        src = Path(src_string)
        dest = Path(dest_string)
        Config(desc, src, dest).remove_link()


@dataclass
class PathPicker:
    opts: list[tuple[str, Path]]

@dataclass
class DynPath:
    """To be used with Config() for paths that require in-code creation"""
    get: Callable[[], Path]

class Config:
    OPTIONS: ClassVar[Optional[argparse.Namespace]] = None
    RECORDER: ClassVar[Optional[Recorder]] = None

    def __init__(
            self,
            desc: str,
            src: Path | PathPicker,
            dest: Path | DynPath,
            *,
            custom_check: Optional[Callable[[], Optional[str]]] = None,
    ) -> None:
        self.desc = desc
        self.src = src
        match dest:
            case Path() as path:
                self.dest = path
            case DynPath(get=f):
                if custom_check is not None and custom_check() is None:
                    if custom_check() is None:
                        self.dest = f()
        self.custom_check = custom_check

    def setup_link(self) -> None:
        # helper func
        def setup(desc: str, src: Path, dest: Path) -> None:
            assert self.RECORDER is not None

            dest.symlink_to(src)
            self.RECORDER.register_link(desc, src, dest)
            print_ok(f"{desc}: {dest} => {src}")

        # check if need running
        if self.custom_check is not None:
            match self.custom_check():
                case str(refusal):
                    print_warn(f"{self.desc}: skipped ({refusal})")
                    return
        else:
            if shutil.which(self.desc) is None:
                print_warn(f"{self.desc}: skipped (binary not found)")
                return

        # check if destination is used already
        if self._handle_existence():
            return


        # if all is fine, link
        match self.src:
            case Path() as src:
                setup(self.desc, src, self.dest)
            case PathPicker(opts):
                choice, src = make_choice(self.desc, opts)
                setup(f"{self.desc}/{choice}", src, self.dest)
            case _:
                raise TypeError(f"wrong `src` type: {self.src}")

    def remove_link(self) -> None:
        # helper func
        def unlink(desc: str, dest: Path) -> None:
            assert self.RECORDER is not None

            dest.unlink()
            self.RECORDER.unregister_link(dest)
            print_ok(f"{desc}: unlinked")

        def verbose(msg: str) -> None:
            assert self.OPTIONS is not None

            if self.OPTIONS.verbose >= 1:
                print_warn(msg)


        # check if needs running
        if self.custom_check is not None:
            match self.custom_check():
                case str(refusal):
                    print_warn(f"{self.desc}: skipped ({refusal})")
                    return

        if not self.dest.is_symlink():
            verbose(f"{self.desc}: can't unlink, not a symlink")
            return

        match self.src:
            case Path() as src:
                if src.absolute() == self.dest.resolve():
                    unlink(self.desc, self.dest)
                else:
                    verbose(
                        f"{self.desc}: won't unlink, doesn't link to config"
                    )
            case PathPicker(opts):
                for _alternative_desc, alternative_src in opts:
                    if alternative_src.absolute() == self.dest.resolve():
                        unlink(self.desc, self.dest)
                        break
                else:
                    verbose(
                        f"{self.desc}: won't unlink, doesn't link to config"
                    )

    def _handle_existence(self) -> bool:
        assert self.OPTIONS is not None

        if self.dest.exists():
            if self.dest.is_symlink():
                print(f"{self.desc}: skipped (already there)")
            else:
                print_warn(f"{self.desc}: skipped (taken)")
            if self.OPTIONS.verbose >= 1:
                if self.dest.is_symlink():
                    print_warn(
                            "\texplanation:"
                            " destination is taken by [symlink to {}]"
                                .format(self.dest.resolve())
                    )
                else:
                    print_warn(f"\texplanation: destination is taken by non-symlink")

            if self.OPTIONS.verbose >= 2:
                if self.dest.is_dir():
                    file_num = 0
                    dir_num = 0
                    link_num = 0
                    for child in self.dest.iterdir():
                        if child.is_file():
                            file_num += 1
                        if child.is_dir():
                            dir_num += 1
                        if child.is_symlink():
                            link_num += 1

                    print_warn(
                            "\tnote: it's a directory with"
                            f" {file_num} files,"
                            f" {dir_num} dirs,"
                            f" {link_num} links."
                    )
            return True
        return False


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

def check_missed(configs: list[Config], dotfiles: Path) -> list[FsNode]:
    taken = []
    for config in configs:
        match config.src:
            case Path() as src:
                taken.append(src.name)
            case PathPicker(opts):
                for _sub_desc, alternative in opts:
                    taken.append(alternative.name)

    potentially_missed: list[FsNode] = []
    ignore_list = list(load_ignore_file())
    for root, dirs, files in dotfiles.walk():
        skiplist = [
            fnmatch.filter(dirs, skippath) for skippath in ignore_list
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

def dotfiles_dir(options: argparse.Namespace) -> Path:
    if options.verbose >= 1:
        print_warn("warning: assuming current directory as the dotfiles root")
    return Path.cwd()

def link_all(configs: list[Config]) -> None:
    print_ok("Setting links up...")
    for config in configs:
        config.setup_link()

def unlink_all(configs: list[Config]) -> None:
    print_ok("Removing links...")
    for config in configs:
        config.remove_link()

def show_log(recorder: Recorder, home: Path, dotfiles: Path) -> None:
    print_ok("Getting registered operations...")
    for i, config in recorder.numbered_configs():
        # registered cofigs are always trivial
        assert isinstance(config.src, Path)

        src = pretty_path(config.src, home, dotfiles)
        dest = pretty_path(config.dest, home, dotfiles)
        print(
            f"{i} @ {config.desc}: {src} => {dest}",
        )

def display_missed(configs: list[Config], dotfiles: Path) -> None:
    print_ok("Checking paths that aren't in the config...")
    miss = False
    for missed in check_missed(configs, dotfiles):
        miss = True
        print(f"\t{missed.current()}")
    if not miss:
        print_ok("you're good!")

def check_configs(configs: list[Config]) -> None:
    print_ok("Checking paths in config for validity...")
    miss = False
    for config in configs:
        match config.src:
            case Path() as path:
                if not path.exists():
                    miss = True
                    print_warn(f"\t{config.desc}: warning, {path} doesn't exist")
            case PathPicker(opts):
                for alternative_desc, alternative_src in opts:
                    if not alternative_src.exists():
                        miss = True
                        print_warn(
                            "\t{desc}: warning, {path} doesn't exist"
                                .format(
                                    desc=f"{config.desc}/{alternative_desc}",
                                    path=alternative_src,
                                )
                        )
    if not miss:
        print_ok("you're good!")

def option_parser() -> argparse.Namespace:
    # cmdline parsing
    prog = sys.argv[0]
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=
        "=" * 50 +
            "\nThis program will help you to manage your dotfiles."
            "\n"
            "\nThe most straightforward argument is probably `link-all`."
            "\nThis will link every dotfile in the config:"
            f"\n\t{prog} --link-all"
            "\nIf you've changed the underlying file structure, use"
            " `redo-all`."
            f"\n\t{prog} --redo-all"
            "\nOr if you want to be more delicate, maybe use `undo ID`."
            "\n"
        + "=" * 50)

    # main operations
    parser.add_argument(
            "--link-all",
            help="link all dotfiles in the config",
            action="store_true"
    )
    parser.add_argument(
            "--show-log",
            help="show all registered operations",
            action="store_true"
    )
    # management
    parser.add_argument(
            "--undo",
            help="undo specific ID-th operation",
            type=int,
            metavar="ID",
    )
    parser.add_argument(
            "--redo-all",
            help="undo all registered operations and re-apply config",
            action="store_true",
    )
    parser.add_argument(
            "--undo-all",
            help="undo all registered operations",
            action="store_true",
    )
    # for manual testing
    parser.add_argument(
            "--unlink-all",
            help="unlink all dotfiles in the config",
            action="store_true"
    )
    parser.add_argument(
            "--relink-all",
            help="unlink and relink all dotfiles in the config",
            action="store_true"
    )
    # misc
    parser.add_argument(
            "-v", "--verbose",
            help="be verbose (can be repeated up to -vv)",
            default=0,
            action="count"
    )
    parser.add_argument(
            "--no-check",
            help="don't check missed from config dotfiles",
            action="store_true")
    # force-feed help when no arguments were supplied
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)
    return parser.parse_args()

def main() -> None:
    # setup
    options = option_parser()
    recorder = Recorder()

    home = Path.home()
    dotfiles = dotfiles_dir(options)

    Config.OPTIONS = options
    Config.RECORDER = recorder
    c = Config

    # configs
    configs: list[Config] = [
        # cli
        c("tmux", dotfiles / "tmux/.tmux.conf", home / ".tmux.conf"),
        c("zsh", dotfiles / "shells/zsh/zshrc", home / ".zshrc"),
        c("fish", dotfiles / "shells/fish", home / ".config/fish"),
        c("nvim", dotfiles / "editors/nvim", home / ".config/nvim"),
        c("most", dotfiles / "pagers/most/.mostrc", home / ".mostrc"),
        # GUI
        c("mpv", dotfiles / "other/mpv", home / ".config/mpv"),
        c("kitty", dotfiles / "terminals/kitty", home / ".config/kitty"),
        c(
            "alacritty",
            PathPicker([
                ("mac", dotfiles / "terminals/alacritty-mac"),
            ]),
            home / ".config/alacritty",

        ),
        # has a dynamic target based on profile and OS
        c(
            "firefox",
            dotfiles / "browser/firefox/user.js",
            DynPath(
                # check about:support for profile folder
                lambda: Path(os.environ["FIREFOX_PROFILE_HOME"]) / "user.js",
            ),
            custom_check=
                lambda:
                    "no $FIREFOX_PROFILE_HOME provided"
                    if os.getenv("FIREFOX_PROFILE_HOME") is None
                    else None,
        ),
        # X11 specific
        c("rofi", dotfiles / "other/rofi", home / ".config/rofi"),
        c("i3", dotfiles / "wm/i3", home / ".config/i3"),
        c("polybar", dotfiles / "wm/bars/polybar", home / ".config/polybar"),
        c("picom", dotfiles / "wm/compositors/picom", home / ".config/picom"),
    ]

    dummy: Any = ""
    ignored: list[Config] = [
        # based on vimscript, will need deleting anyway
        c("nvim-old", dotfiles / "editors/nvim-old", dummy),
    ]
    all_configs = configs + ignored

    # command execution
    if options.link_all:
        link_all(configs)

    if options.show_log:
        show_log(recorder, home, dotfiles)

    match options.undo:
        case int(oid):
            recorder.undo_by_oid(oid)

    if options.redo_all:
        recorder.undo_all()
        link_all(configs)

    if options.undo_all:
        recorder.undo_all()

    if options.unlink_all:
        unlink_all(configs)

    if options.relink_all:
        unlink_all(configs)
        link_all(configs)

    if not options.no_check:
        display_missed(all_configs, dotfiles)
        check_configs(all_configs)

if __name__ == "__main__":
    main()
