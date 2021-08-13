# track and calculate lifetime of gcert certificate

EXPIRY_FILE="/tmp/.gcert_expiration"

gcert_expiry_update() {
  gcertstatus -show_expiration_time | grep LOAS2 | sed "s/LOAS2 expires at //" > "$EXPIRY_FILE"
}

gcert_expiry_check_update() {
  if [[ "${ZSH_THEME_GCERT_PROMPT_PARANOID:=false}" != true ]]; then
    if [[ ! -f "$EXPIRY_FILE" ]]; then
      gcert_expiry_update
    elif history | tail -1 | awk '{print $2}' | grep -v gcertstatus | grep -q gcert; then
      gcert_expiry_update
    fi
  fi
}

gcert_expiration_from_epoch() {
  strftime -r "%Y-%m-%d %R" "$(< $EXPIRY_FILE)"
}

prompt_gcert() {
  emulate -L zsh
  gcert_expiry_check_update
  local -i expiration_time remaining_hours remaining_minutes
  local gcert_state glyph fg bg msg
  expiration_time=$(gcert_expiration_from_epoch)
  remaining_hours=$(( ($expiration_time - $EPOCHSECONDS) / 3600 ))
  remaining_minutes=$(( (($expiration_time - $EPOCHSECONDS) / 60) % 60 ))
  if [[ $remaining_hours -lt 0 || $remaining_minutes -lt 0 ]]; then
    gcert_state=EXPIRED
    fg=red
    bg=black
    msg=${POWERLEVEL9K_GCERT_EXPIRED_MESSAGE:=Expired}
  elif [[ $remaining_hours -lt ${POWERLEVEL9K_GCERT_LOW_THRESHOLD=2} ]]; then
    gcert_state=LOW
    fg=yellow
    bg=black
    msg=${POWERLEVEL9K_GCERT_LOW_MESSAGE:=${remaining_hours}h ${remaining_minutes}m}
  else
    gcert_state=NORMAL
    fg=green
    bg=black
    msg=${POWERLEVEL9K_GCERT_NORMAL_MESSAGE:=${remaining_hours}h ${remaining_minutes}m}
  fi
  glyph=$'\uf623'

  p10k segment -s ${gcert_state} -i "$glyph" +r -f $fg -b $bg -t "$msg"
}

gcert_prompt_time() {
  emulate -L zsh
  gcert_expiry_check_update
  local -i expiration_time remaining_hours remaining_minutes
  expiration_time=$(gcert_expiration_from_epoch)
  remaining_hours=$(( ($expiration_time - $EPOCHSECONDS) / 3600 ))
  remaining_minutes=$(( (($expiration_time - $EPOCHSECONDS) / 60) % 60 ))
  if [[ $remaining_hours -lt 0 || $remaining_minutes -lt 0 ]]; then
    echo "${ZSH_THEME_GCERT_PROMPT_EXPIRED=expired}"
  elif [[ $remaining_hours -lt ${ZSH_THEME_GCERT_PROMPT_WARN_HOURS=2} ]]; then
    echo "${ZSH_THEME_GCERT_PROMPT_WARN_PREFIX}${remaining_hours}h ${remaining_minutes}m${ZSH_THEME_GCERT_PROMPT_WARN_POSTFIX}"
  else
    echo "${ZSH_THEME_GCERT_PROMPT_PREFIX}${remaining_hours}h ${remaining_minutes}m${ZSH_THEME_GCERT_PROMPT_POSTFIX}"
  fi
}