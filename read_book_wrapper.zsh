
function session() {

  local TMUX_SESSION_DIR="${XDG_CONFIG_HOME}"'/tmux/sessions/'
  local args="${*}"
  local name=''

  if [[ -z $args ]]; then
    name=$(fzf "${TMUX_SESSION_DIR}" | sed '/^$/d')
  else
    name="${1}"
  fi

  local filename="${TMUX_SESSION_DIR}""${name}"

  if [[ ! -f "${filename}" ]]; then
    echo "${filename}" 'not found'
    return 1
  fi

  local tmp_dir="${XDG_RUNTIME}"'/tmux/'
  local socket="${tmp_dir}"'tmux-'"${UID}"'/'"${name}"
  local has_session=$(tmux -S "${socket}" has-session -t "${name}" 2> /dev/null; echo "${?}")

  if [[ "${has_session}" == '0' ]]; then
    local has_attached_clients=$(tmux -S "${socket}" ls -F '#{session_attached}' 2> /dev/null | tail -n1)
    tmux -S "${socket}" attach 2>/dev/null
  else
    mkdir -p "${tmp_dir}"'tmux-'"${UID}"'/'
    tmux -S "${socket}" -f "${filename}" attach 2>/dev/null
  fi

}

function read_books() {

  function get_rate() {
    local default_rate=$(redis-cli get reading_speed)

    if [[ -z $default_rate ]]; then
      default_rate=1.0
    fi    

    echo $default_rate
  }

  local rate

  if [[ $1 ]]; then
    rate=$1

    if [[ $rate -gt 0 ]]; then
      rate=$((1.0 / rate))
    else
      rate=$(get_rate)
    fi

    redis-cli set reading_speed $rate 1> /dev/null
  else
    rate=$(get_rate)
  fi

  systemctl --user restart read_book

}

