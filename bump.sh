#!/bin/bash

# The goal of this script is to bump the current project version

# Do some clean up
clear

# Ensure it's run from the correct path
plist="Client/Info.plist"
if [ ! -f "$plist" ]; then
  echo "[x] Please run this script from the root of the project with ./bump.sh"
  exit 0
fi

# Ensure git status is clean
if [ -z "$(git status --porcelain)" ]; then
  echo "[i] Git status clean, proceeding"
else
  echo "[x] Git status not clean, aborting"
  exit 0
fi

# Extract actual values
versionNumber=$(git for-each-ref --sort='-authordate' | grep '.*refs/remotes/origin/delivery/bump-' | head -1 | rev | cut -d'-' -f 1-2 | rev | cut -d'-' -f 1)
buildNumber=$(git for-each-ref --sort='-authordate' | grep '.*refs/remotes/origin/delivery/bump-' | head -1 | rev | cut -d'-' -f 1-2 | rev | cut -d'-' -f 2)

# Ask for version number and check formatting is correct
echo "[?] The version number is $versionNumber, what is the new value? [xxx.yy.zz]"
newVersionNumber=
while [[ $newVersionNumber = "" ]]; do
  read newVersionNumber
  if [[ ! $newVersionNumber =~ ^[0-9]+(\.[0-9]+){2}$ ]];
  then
    echo "[x] Wrong format. Try again. [xxx.yy.zz]"
    newVersionNumber=
  fi
done

# Ask for build number and check formatting is correct
echo "[?] The build number is $buildNumber, what is the new value? [v]"
newBuildNumber=
while [[ $newBuildNumber = "" ]]; do
  read newBuildNumber
  if [[ ! $newBuildNumber =~ ^[0-9]+$ ]];
  then
    echo "[x] Wrong format. Try again. [v]"
    newBuildNumber=
  fi
done

# Ask for confirmation
echo "[?] Are you sure you want to bump from $versionNumber($buildNumber) to $newVersionNumber($newBuildNumber)? [Yy/Nn]"
areYouSure=
while [[ $areYouSure = "" ]]; do
  read areYouSure
done

if [ "$areYouSure" = "Y" ] || [ "$areYouSure" = "y" ]; then
  echo "[v] Bumping to $newVersionNumber($newBuildNumber)!"
else
  echo "[v] Ok bye."
  exit 0
fi

# Go to master, pull, create a branch, bump, add changes, commit, push.
branchName="delivery/bump-$newVersionNumber-$newBuildNumber"
git checkout qwant-develop
git pull
git checkout -b "$branchName"
agvtool new-marketing-version $newVersionNumber
agvtool new-version -all $newBuildNumber
git add *
git commit -m "[Qwant] Bump version to $newVersionNumber-$newBuildNumber"
git push origin -u "$branchName"

echo "[v] All done, bye!"

