import re
import sys
from typing import Iterator


def command_color(s: str, flag: bool):
    if flag:
        return f"\033[1m{s}\033[0m\033"
    else:
        return f"\033[36m{s}\033[0m"


def makefile_docs() -> Iterator[tuple[str, str, bool]]:
    with open("Makefile", "r") as f:
        for line in f:
            if line.startswith("##"):
                docstring = line.strip("## ").rstrip()
                # in some cases there are comments between the docstring for the
                # command, and the command itself, so we need to skip those lines
                cmd_name = re.match(r"^([a-z_-]+):", f.readline())
                while not cmd_name:
                    cmd_name = re.match(r"^([a-z_-]+):", f.readline())
                command = "make " + cmd_name.group(1)
                yield command, docstring, False
            elif line.startswith("#-"):
                title = line.strip("#- ").rstrip()
                # get the make command immediately after a docstring
                yield title, " ", True


def print_makefile_docs(title: str) -> None:
    header = f"Makefile commands for {title}"
    print()
    print(header)
    print("-" * len(header))

    # print make command and docstring in two columns
    for cmd, doc, flag in makefile_docs():
        print(f'{command_color(cmd, flag):<35}{":":4}{doc:<12}')


if __name__ == "__main__":
    print_makefile_docs(title=sys.argv[1])
