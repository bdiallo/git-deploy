#!/bin/bash
# Git push then pull over ssh
# Script based on https://github.com/sunny/git-deploy

set -e

info(){
  echo -e "* \033[1m""$@""\033[0m"
}

# set variables from parameters
REMOTE_LOCAL_NAME=${1:-origin} # 1st argument or default to remote origin
ENV=${2:-staging}   # 2nd argument or default to staging
REMOTE_SERVER_NAME="origin" # name of the git remote on deployed server

# If you need to run local scripts before deployment (knock, for example)
if [ -f __scripts/deploy_before ]; then
  info "__scripts/deploy_before $ENV"
  __scripts/deploy_before "$ENV"
fi

BRANCH=`git branch 2> /dev/null | sed -n '/^\*/s/^\* //p'` # local branch to send to REMOTE
REMOTE_URL=`git config --get remote.$REMOTE_LOCAL_NAME.url`           # remote url
HOST=${REMOTE_URL%%:*}                                     # HOST=user@remote_server
GIT_DIR=${REMOTE_URL#*:}                                   # bare repository location on REMOTE
ENV_DIR="${GIT_DIR%/*}"/$ENV                               # project env dir on REMOTE


info "Sending branch $BRANCH"
git push $REMOTE_LOCAL_NAME HEAD

# ssh to HOST and execute all commands between ""
ssh -T $HOST "

# Force your script to exit on error from where the 1st error occurred
set -e

cd $ENV_DIR
git fetch $REMOTE_SERVER_NAME

CURRENT_BRANCH=\`git branch 2> /dev/null | sed -n '/^\*/s/^\* //p'\`
(git branch 2> /dev/null | grep -n '^  $BRANCH') && HAS_BRANCH=1 || HAS_BRANCH=0

# Change branch
if [ $BRANCH != \$CURRENT_BRANCH ]; then

  # Create remote tracked branch
  if [ \$HAS_BRANCH != 1 ]; then
    echo '* Creating $BRANCH branch in $ENV'
    git checkout -t $REMOTE_SERVER_NAME/$BRANCH

  # Switch to it
  else
    echo '* Switching to $BRANCH branch in $ENV'
    git checkout $BRANCH --
  fi

  # Launch post-merge if file .git/hooks/post-merge is executable
  [ -x .git/hooks/post-merge ] && .git/hooks/post-merge

# Pull
else
  echo '* Pulling $BRANCH in $ENV'
  git merge $REMOTE_SERVER_NAME/$BRANCH --ff-only
fi
"

# For compile scripts (Compass, CoffeeScript, etc…)
if [ -f __scripts/compile ]; then
  info "__scripts/compile $ENV"
  ssh -T $HOST "cd $ENV_DIR && __scripts/compile $ENV"
fi


# For local extra deploy scripts (database, for example)
if [ -f __scripts/deploy ]; then
  info "__scripts/deploy $ENV"
  __scripts/deploy "$ENV"
fi

info "Tag $ENV"
git tag -f $ENV
git push -f $REMOTE_LOCAL_NAME HEAD

echo "Oh yeah! 👍"
