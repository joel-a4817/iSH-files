alias C='calcurse -D ~/.local/share/calcurse/compass'
alias c='calcurse'
Cs() {
  rm -rf ~/.local/share/calcurse/compass.ics ~/.local/share/calcurse/compass
  curl -L -o ~/.local/share/calcurse/compass.ics "https://mhs-vic.compass.education/download/sharedCalendar.aspx?uid=19030&key=de953c62-f1e9-475d-b0c2-83fd3c09ff62&c.ics"
  calcurse -D ~/.local/share/calcurse/compass -i ~/.local/share/calcurse/compass.ics
  rm -rf ~/.local/share/calcurse/personal.ics
  cd ~/.local/share/calcurse
  calcurse -x > personal.ics
}
Cp() {
  rm -rf ~/.local/share/calcurse/personal.ics
  cd ~/.local/share/calcurse
  calcurse -x > personal.ics
  echo "personal.ics merge complete" 
  cp -f ~/.local/share/calcurse/todo ~/text/Calendar
  cp -rf ~/.local/share/calcurse/notes ~/text/Calendar
  echo "todo, notes merge complete"
}
mplete"
}
