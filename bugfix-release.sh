#!/bin/bash
set -ex

git config --global user.name $SNAP_STAGE_TRIGGERED_BY
git config --global user.email $EMAIL

mvn -Psonatype-oss-release release:clean
mvn -Psonatype-oss-release -Dgpg.passphrase="$GPG_PASSPHRASE" --batch-mode clean release:prepare -DautoVersionSubmodules=true
mvn -Psonatype-oss-release -Dgpg.passphrase="$GPG_PASSPHRASE" release:perform
mvn -Psonatype-oss-release release:clean
