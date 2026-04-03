from pathlib import Path

from config import Config, check_missed


def missed_paths(configs: list[Config], dotfiles: Path) -> list[Path]:
    return sorted(node.current() for node in check_missed(configs, dotfiles))


def test_fully_unmanaged_tree_is_reported_as_root_directory(
    tmp_path: Path,
) -> None:
    """
    Fully unmanaged tree check

    If nothing under dotfiles root is claimed by config, `Config.check_missed()`
    should report the root directory as the missed entry.
    """
    (tmp_path / "README.md").write_text("root readme")

    assert missed_paths([], tmp_path) == [tmp_path]


def test_fully_managed_directory_produces_no_misses(tmp_path: Path) -> None:
    """
    Fully managed directory check

    If a directory is entirely claimed by a config entry, `Config.check_missed()`
    should not report anything under it.
    """
    (tmp_path / "shells" / "zsh").mkdir(parents=True)

    configs = [
        Config("shells", tmp_path / "shells", tmp_path / "dest"),
    ]

    assert missed_paths(configs, tmp_path) == []


def test_ignore_file_can_hide_unmanaged_file(
    tmp_path: Path,
    monkeypatch,
) -> None:
    """
    Ignore-file support check

    If `.configignore` names a file, `Config.check_missed()` should not report
    that file as missed.
    """
    (tmp_path / ".configignore").write_text("README.md\n")
    (tmp_path / "README.md").write_text("root readme")

    monkeypatch.chdir(tmp_path)

    assert missed_paths([], tmp_path) == [tmp_path]


def test_root_level_untracked_file_is_reported_even_when_nested_config_exists(
    tmp_path: Path,
) -> None:
    """
    (Un)related ancestry check

    `Config.check_missed()` should still report unrelated root-level files even
    when some nested directory is already claimed by a config entry.
    """
    (tmp_path / "README.md").write_text("root readme")
    (tmp_path / "shells" / "zsh").mkdir(parents=True)

    configs = [
        Config("zsh", tmp_path / "shells" / "zsh", tmp_path / "dest"),
    ]

    assert missed_paths(configs, tmp_path) == [tmp_path / "README.md"]


def test_dirty_directory_reports_untracked_file_at_its_real_path(
    tmp_path: Path,
) -> None:
    """
    Proper path reporting check

    If you have a directory where one subentry is managed, but the other is
    not, one that is unmanaged should be reported at the correct path
    """
    (tmp_path / "shells" / "zsh").mkdir(parents=True)
    (tmp_path / "shells" / "README.md").write_text("nested readme")

    configs = [
        Config("zsh", tmp_path / "shells" / "zsh", tmp_path / "dest"),
    ]

    assert missed_paths(configs, tmp_path) == [
        tmp_path / "shells" / "README.md"
    ]
