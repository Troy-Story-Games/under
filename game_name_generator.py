"""Step 1: Generate the name of the game to avoid thinking."""
from ast import arg
from multiprocessing.sharedctypes import Value
import os
import sys
import random
import argparse
from typing import List

from pkg_resources import require

TOO_LONG_SUBTITLE = "Dig Yourself Into a Hole"


def get_name(words: List[str], number: int) -> str:
    """
    Get a random name give a set of words.

    :param words: List of words to choose from.
    :param number: Number of words in the name.
    :returns: A random name.
    """
    ret = []
    for _ in range(number):
        ret.append(random.choice(words))
    return ' '.join(ret)


def validate_args(args: argparse.Namespace):
    """Validate the arguments to the program. Exits on failure."""
    if not os.path.exists(args.input):
        print(f"Input file {args.input} does not exist.")
        sys.exit(1)

    if args.number <= 0:
        print(f"--number must be 1 or greater")
        sys.exit(1)

    if args.count <= 0:
        print(f"--count must be 1 or greater")
        sys.exit(1)


def read_words(fpath: str) -> List[str]:
    """Read the words from a file. Return as a list of strings."""
    words = []
    with open(fpath, "r", encoding="utf-8") as fh:
        for line in fh.read().splitlines():
            words.extend([x.strip().capitalize() for x in line.split() if x])
    return words


def main():
    """Entry Point."""
    parser = argparse.ArgumentParser(description="Generate the name of our game")
    parser.add_argument("-i", "--input", help="Input for words to pick from", required=True)
    parser.add_argument("-c", "--count", help="Number of names to generate", default=10, type=int)
    parser.add_argument("-n", "--number", help="Number of words in title", default=3, type=int)
    args = parser.parse_args()
    validate_args(args)  # Exits on failure

    # Get the words
    words = read_words(args.input)

    for _ in range(args.count):
        print(f"{get_name(words, args.number)}: {TOO_LONG_SUBTITLE}")


if __name__ == "__main__":
    main()