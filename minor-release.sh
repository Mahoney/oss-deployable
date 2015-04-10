#!/bin/bash
set -ex

git config --global user.name $SNAP_STAGE_TRIGGERED_BY
git config --global user.email $EMAIL

function printVersion {
  mvn help:evaluate -Dexpression=project.version | grep -v INFO | grep -v WARNING | grep SNAPSHOT
}

function getPromotedVersion {
  checkoutCommitToPromote > /dev/null
  printVersion
}

function checkoutCommitToPromote {
  git clean -fdx
  git checkout $SNAP_COMMIT
}

function assertReleasable {
  local versionToRelease=$1
  local currentVersion=`getMasterVersion`
  if [ $currentVersion != $versionToRelease ]
  then
    echo "Master is at $currentVersion - you may not re-release $versionToRelease"
    exit 1
  fi
}

function getMasterVersion {
  checkoutMaster > /dev/null
  printVersion
}

function checkoutMaster {
  git clean -fdx
  git checkout master
  git fetch
  git merge origin/master
}

function calculateReleaseBranchName {
  local versionToRelease=$1
  local majorVersion=`echo ${versionToRelease} | cut -d"." -f1`
  local minorVersion=`echo ${versionToRelease} | cut -d"." -f2`
  echo RELEASE-$majorVersion.$minorVersion
}

function createBranch {
  local branchName=$1
  checkoutCommitToPromote
  set +e
  echo "deleting $branchName if it exists - ignore error saying it does not exist, that's expected"
  git branch -D $branchName
  git push origin :$branchName
  set -e
  git checkout -b $branchName
  git push origin $branchName
}

function updateMasterVersions {
  checkoutMaster
  local versionToRelease=$1
  local newVersion=`calculateNewVersion $versionToRelease`
  mvn --batch-mode release:update-versions -DautoVersionSubmodules=true -DdevelopmentVersion=$newVersion
  local updatedVersion=`printVersion`
  if [ $updatedVersion != $newVersion ]
  then
    echo "Maven release plugin failed to update $versionToRelease to $newVersion"
    exit 1
  fi

  git commit -a -m "Updated master maven version from $versionToRelease to $newVersion"
  git push origin master
}

function calculateNewVersion {
  local versionToRelease=$1
  local majorVersion=`echo ${versionToRelease} | cut -d"." -f1`
  local minorVersion=`echo ${versionToRelease} | cut -d"." -f2`
  echo $majorVersion.`expr $minorVersion + 1`.0-SNAPSHOT
}

VERSION_TO_RELEASE=`getPromotedVersion`
assertReleasable $VERSION_TO_RELEASE
RELEASE_BRANCH_NAME=`calculateReleaseBranchName $VERSION_TO_RELEASE`
createBranch $RELEASE_BRANCH_NAME
updateMasterVersions $VERSION_TO_RELEASE
