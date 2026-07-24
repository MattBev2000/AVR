from __future__ import annotations

import argparse
import subprocess
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


@dataclass
class GitResult:
    command: list[str]
    returncode: int
    stdout: str
    stderr: str

    @property
    def ok(self) -> bool:
        return self.returncode == 0


def run_git(repo: Path, args: list[str]) -> GitResult:
    command = ["git", *args]
    process = subprocess.run(
        command,
        cwd=repo,
        text=True,
        capture_output=True,
        check=False,
    )

    return GitResult(
        command=command,
        returncode=process.returncode,
        stdout=process.stdout.strip(),
        stderr=process.stderr.strip(),
    )


def find_git_repositories(root: Path) -> list[Path]:
    repositories: list[Path] = []

    for directory in root.rglob(".git"):
        if directory.is_dir():
            repo = directory.parent
            repositories.append(repo)

    return sorted(set(repositories))


def is_github_repository(repo: Path) -> bool:
    result = run_git(repo, ["remote", "-v"])

    if not result.ok:
        return False

    return "github.com" in result.stdout.lower()


def has_changes(repo: Path) -> bool:
    result = run_git(repo, ["status", "--porcelain"])

    if not result.ok:
        raise RuntimeError(result.stderr or "Unable to read git status.")

    return bool(result.stdout)


def push_repository(repo: Path, commit_message: str, dry_run: bool = False) -> bool:
    print(f"\nRepository: {repo}")

    if not is_github_repository(repo):
        print("Skipped: remote is not GitHub.")
        return False

    if not has_changes(repo):
        print("Skipped: no changes to commit.")
        return False

    commands = [
        ["add", "."],
        ["commit", "-m", commit_message],
        ["push"],
    ]

    for args in commands:
        print(f"Running: git {' '.join(args)}")

        if dry_run:
            continue

        result = run_git(repo, args)

        if not result.ok:
            if result.stdout:
                print(result.stdout)
            if result.stderr:
                print(result.stderr)
            raise RuntimeError(f"Command failed in {repo}: git {' '.join(args)}")

        if result.stdout:
            print(result.stdout)

    print("Done.")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Find GitHub repositories and run git add, commit, and push on each one."
    )
    parser.add_argument(
        "root",
        nargs="?",
        default=".",
        help="Folder where the search starts. Default: current folder.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without running git add, commit, or push.",
    )

    args = parser.parse_args()

    root = Path(args.root).resolve()

    if not root.exists() or not root.is_dir():
        print(f"Invalid folder: {root}")
        return 1

    commit_message = f"backup-{datetime.now().strftime('%Y-%m-%d')}"
    repositories = find_git_repositories(root)

    if not repositories:
        print(f"No git repositories found in {root}")
        return 0

    print(f"Search folder: {root}")
    print(f"Commit message: {commit_message}")
    print(f"Repositories found: {len(repositories)}")

    pushed_count = 0
    failed_count = 0

    for repo in repositories:
        try:
            pushed = push_repository(repo, commit_message, dry_run=args.dry_run)
            if pushed:
                pushed_count += 1
        except RuntimeError as error:
            failed_count += 1
            print(f"Error: {error}")

    print("\nSummary")
    print(f"Pushed repositories: {pushed_count}")
    print(f"Failed repositories: {failed_count}")
    print(f"Skipped repositories: {len(repositories) - pushed_count - failed_count}")

    return 1 if failed_count else 0


if __name__ == "__main__":
    raise SystemExit(main())
