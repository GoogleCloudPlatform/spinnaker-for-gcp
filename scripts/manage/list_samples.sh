#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

bold "Here is a list of sample applications available to install. Selecting one will launch" \
      "a tutorial to install it."

PS3='Please enter your choice: '

tutorials=($(ls -d ~/cloudshell_open/spinnaker-for-gcp/samples/*/ | xargs -n 1 basename) "Quit")

select tutorial in "${tutorials[@]}"
do
  case $tutorial in
    "Quit")
      break
      ;;
    "")
      bold "Please choose a valid entry (1-${#tutorials[@]})";;
    *)
      bold "Launching $tutorial tutorial..."
      cloudshell launch-tutorial ~/cloudshell_open/spinnaker-for-gcp/samples/$tutorial/install.md
      break
      ;;
  esac
done
