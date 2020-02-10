#!/bin/sh

set -eux

git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch --prune
git remote set-head origin -d
git branch -a || 'true'
git push --prune dest +refs/remotes/origin/*:refs/heads/* +refs/tags/*:refs/tags/*
