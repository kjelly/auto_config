#!/usr/bin/env python
import os.path
import os


def main():
    dropbox_path = os.path.expanduser("~/Dropbox")
    wiki_command = "bash -c 'cd ~/Dropbox/vimwiki/;vim +VimwikiIndex'"
    dropbox_command = "dropbox start"
    if os.path.islink(dropbox_path):
        os.system(wiki_command)
    else:
        os.system(dropbox_command)
        os.system(wiki_command)


if __name__ == "__main__":
    main()
