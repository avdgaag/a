if [[ ! -o interactive ]]; then
    return
fi

compctl -K _a a

_a() {
  local word words completions
  read -cA words
  word="${words[2]}"

  if [ "${#words}" -eq 2 ]; then
    completions="$(a commands)"
  else
    completions="$(a completions "${word}")"
  fi

  reply=("${(ps:\n:)completions}")
}
