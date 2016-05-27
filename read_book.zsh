#!/usr/bin/zsh

# Specifications: While a book is visible, the cursor is advanced with a delay
# relative to the length of the word under the cursor.
#
# Basic steps: Check that a window already exists, and if it does, exit early
# (as this is already running elsewhere).  If no window exists, create one,
# then move it and activate the window.  Wait until the tmux server recognises
# that a window is attached (as it must be if the window has been created with
# the command to attach the session) before continuing.  
#
# Special cases: If the session doesn't exist or the server command fails,
# exits early with the error message.  
#
# If another instance of this function is already running, exit early with a
# message.  How to detect that this function is running already?  I don't have
# a simple solution without using systemd to manage running this function and
# aliasing something to start that service instead of calling this function
# directly.
#
# Pre-conditions: A tmux session with a specific socket must exist and must be
# running an instance of vim with an identifiable server name.  An existing
# window must not be attached to the books session.
#
# Loop invariant: An attached tmux window on the books session.
#
# Exit condition: No windows are attached to the books session.
#
# Post-conditions: There is no window attached to the books session.
#
# Ending: Books window was attached, then was later detached.  Other instances
# of this script may then be created.
#
# Make progress: Each iteration of the loop either stalls (if the window is
# inactive), or advances the word under the cursor.
#
# Main steps: Advances the word under the cursor, then checks the length of
# the word under the cursor, then delays for a time relative to the length of
# the word.
#
# Maintain loop invariant: The body of the loop has no control over attaching
# or detaching windows, or otherwise exiting early.  The exit condition holds
# until the user interferes.
#
# 1. Creates a terminal window on the largest monitor and attaches to an
#    existing tmux session running an instance of vim with a text ebook.
# 2. Ensures that the window is visible on the screen.
# 3. Loops while the window is attached to the tmux session.
# 4. Sleeps for an interval if the window is no longer active or the keyboard
#    has been used in the past three seconds.
# 5. Advances the cursor by a word, first placing the cursor over the
#    beginning of the next word, then moving it to the end of the same word.
# 6. Checks the length in characters of word under the cursor and delays the
#    overall advancement speed given a rate passed in as a shell parameter.
# 7. Loops until the window is detached from the tmux session.

export TERM='rxvt-unicode-256color'
rate=$(redis-cli get reading_speed)
servername='BOOKS'
socket=$HOME/.tmp/tmux/tmux-1000/books
window_name='books'

function vim_key() {
  local key=$1
  vim --servername $servername --remote-send $key 2>/dev/null;
}

function vim_expr() {
  local expr=$1
  vim --servername $servername --remote-expr $expr 2>/dev/null
}

function char_count() {
  echo "${cword}" | wc -c
}

function is_attached() {
  tmux -S $socket ls -F '#{session_attached}' 2> /dev/null | sort -ur | head -n1
}

function session_active() {
  tmux -S $socket has-session -t 'books'
}

function make_window() {

  # Establishes the loop invariant: Creates a new window attached to the
  # books section.

  # Appears with large font size, red text, and blue cursor
  local class_name='bigspaceurxvt'
  local desktop=2

  if [[ $(hostname) == 'laptop' ]]; then
    class_name='bigspacelaptop' 
  fi

  if [[ $(is_attached) == '0' ]]; then
    wmctrl -s $desktop 2> /dev/null
    urxvtc -name $class_name -e zsh -c 'zsh -ic "books"'
    wmctrl -r $window_name -t $desktop 2> /dev/null
  fi

  clear

  while [[ $(is_attached) -eq 0 ]]; do;
    session_active || return

    sleep 0.1
  done

  wmctrl -a $window_name 2> /dev/null
}

function delay() {
  local seconds=$1
  sleep $(($seconds * $rate));
}

function active_window() {
  xdotool getactivewindow getwindowname 2>/dev/null
}

function () {

  # Basic steps

  if [[ ! -z $1 ]]; then
    rate=$1
    # redis-cli --raw set reading_speed $1
    rate=$((1 / rate))
  else
    # rate=$((redis-cli get reading_speed))
  fi

  make_window

  while [[ $(is_attached) ]]; do
    local idle=$(xprintidle)

    if [[ $(is_attached) == '0' ]]; then
      break
    fi

    # Sleep if window is inactive (not focused)
    if [[ $((idle / 1000)) -lt 3 || $(active_window) != $window_name ]]; then
      sleep 1
      continue
    fi

    # Main steps
    vim_key '<Esc>'
    vim_key 'zz'

    delay 0.01

    # Make progress
    vim_key '<Esc>'
    vim_key 'w'

    # Delay while cursor is over longer words
    local cword=$(vim_expr 'expand("<cWORD>")')
    local length=$(char_count $cword);

    if [[ $length -lt 2 ]]; then
      delay 0.1
      continue
    fi

    if [[ $length -gt 7 ]]; then
      delay 0.135
    else
      delay 0.05
    fi

    # Make progress
    vim_key '<Esc>'
    vim_key 'e'

    if [[ $length -gt 7 ]]; then
      delay 0.135
    else
      delay 0.05
    fi
  done

}

