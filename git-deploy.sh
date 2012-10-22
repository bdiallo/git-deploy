#!/bin/bash
# Git push then pull over ssh
#
# Supposing you have these environments on the same ssh git remote:
#   project/origin.git
#   project/dev/.git
#   project/prod/.git
#
# You can then push the current branch and pull it in dev/ and prod/ by doing:
#   $ git deploy dev
#   $ git deploy prod
#
# Installation with ~/bin in your $PATH:
#   $ curl http://gist.github.com/raw/407687/git-deploy.sh > ~/bin/git-deploy
#   $ chmod +x ~/bin/git-deploy
#   $ git config --global alias.deploy '!git-deploy'

set -e

info(){
  echo -e "* \033[1m""$@""\033[0m"
}

REMOTE='origin'
ENV=${1:-dev} # first argument or default to dev

# For local scripts before deploy (knock, for example)
if [ -f __scripts/deploy_before ]; then
  info "__scripts/deploy_before $ENV"
  __scripts/deploy_before "$ENV"
fi

BRANCH=`git branch 2> /dev/null | sed -n '/^\*/s/^\* //p'`
REMOTE_URL=`git config --get remote.$REMOTE.url`
HOST=${REMOTE_URL%%:*}
DIR=${REMOTE_URL#*:}
ENV_DIR="${DIR%/*}"/$ENV


info "Sending $BRANCH"
git push $REMOTE $BRANCH

ssh -T $HOST "

set -e

cd $ENV_DIR
git fetch $REMOTE

CURRENT_BRANCH=\`git branch 2> /dev/null | sed -n '/^\*/s/^\* //p'\`
(git branch 2> /dev/null | grep -n '^  $BRANCH') && HAS_BRANCH=1 || HAS_BRANCH=0

# Change branch
if [ $BRANCH != \$CURRENT_BRANCH ]; then

  # Create remote tracked branch
  if [ \$HAS_BRANCH != 1 ]; then
    echo '** Creating $BRANCH branch in $ENV'
    git checkout -t $REMOTE/$BRANCH

  # Switch to it
  else
    echo '** Switching to $BRANCH branch in $ENV'
    git checkout $BRANCH --
  fi
fi

# Pull
echo '** Pulling $BRANCH in $ENV'
git merge $REMOTE/$BRANCH --ff-only

# For Passenger-like apps
if [ -f 'tmp/restart.txt' ]; then
  echo '** Restarting'
  touch tmp/restart.txt
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
