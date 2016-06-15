I've since reimplemented this in python, so this is deprecated.

This basically sets up a urxvt terminal window that runs vim inside of tmux
and automatically advances the cursor at a given rate.  It's not designed to
work anywhere but my own computer, so don't expect this to be usable.  It
checks the length of the word under the cursor sot that longer words cause
more of a delay.  The window it creates has a huge font size and large line
spacing, red text on black and a default colored cursor.


1. Creates a terminal window on my largest monitor (desktop 2) and attaches to
   an existing tmux session running an instance of vim with a text ebook.  If
   this is already visible, this step is skipped.
2. Ensures that the window is visible on the screen.
3. Loops while the window is attached to the tmux session.
4. Sleeps for an interval if the window is no longer active or the keyboard
   has been used in the past three seconds.
5. Advances the cursor by a word, first placing the cursor over the beginning
   of the next word, then moving it to the end of the same word.
6. Checks the length in characters of word under the cursor and delays the
   overall advancement speed given a rate passed in as a shell parameter.
7. Loops until the window is detached from the tmux session.

Dependencies:

- redis
- rxvt-unicode
- systemd
- tmux
- vim (built with +clientserver)
- wmctrl
- xdotool
- xprintidle
- xrdb
- zsh

