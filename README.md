$ git deploy
============

Git push then pull over ssh.

Usage
---

Supposing you have a git remote over SSH, called origin
(for example : `user@example.org:thatproject/project_bare_repo.git`)
with these directories:

    thatproject/project_bare_repo.git
    thatproject/dev/.git
    thatproject/prod/.git

This script will let you push and pull it in `dev/` and `prod/`, just by calling locally:

```sh
$ git deploy origin dev
$ git deploy origin prod
```


Install
-------

Make sure the `~/bin` folder exists and is in your `$PATH`, then:

```sh
$ curl https://raw.githubusercontent.com/bdiallo/git-deploy/master/git-deploy.sh > ~/bin/git-deploy
$ chmod +x ~/bin/git-deploy
$ git config --global alias.deploy '!git-deploy'
```

Update
------

```sh
$ curl https://raw.githubusercontent.com/bdiallo/git-deploy/master/git-deploy.sh > ~/bin/git-deploy
```

Branches
--------

If the local branch is different from the remote one, it will push it and switch to it
in your remote directory.


Hooks
-----

Other scripts can be launched before and after a deploy by using hooks.
These files will be called in this order during a deploy if they are executable:

| Command | Local | Remote |
| --------- | ------ | ------- |
| `__scripts/deploy_before dev` | X | |
| `.git/hooks/post-merge` | | X |
| `__scripts/compile dev` | | X |
| `__scripts/deploy dev` | X | |
