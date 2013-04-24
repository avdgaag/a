if [[ ! -o interactive ]]; then
    return
fi

compctl -K _ag ag

_ag() {
  local word words completions
  read -cA words
  word="${words[2]}"

  if [ "${#words}" -eq 2 ]; then
    completions="$(ag commands)"
  else
    completions="$(ag completions "${word}")"
  fi

  reply=("${(ps:\n:)completions}")
}
