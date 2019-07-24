bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

GIT_USERNAME=$(git config --global --get user.name)
GIT_EMAIL=$(git config --global --get user.email)

if [ -z "$GIT_USERNAME" ]; then
  bold "Your Git account username is not set. Run 'git config --global user.name \"Your Name\"' and try again."
  exit 1
fi

if [ -z "$GIT_EMAIL" ]; then
  bold "Your Git account email is not set. Run 'git config --global user.email \"you@example.com\"' and try again."
  exit 1
fi