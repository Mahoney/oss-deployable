mvn -Psonatype-oss-release release:clean
mvn -Psonatype-oss-release -Dgpg.passphrase="$GPG_PASSPHRASE" --batch-mode clean release:prepare -DautoVersionSubmodules=true
mvn -Psonatype-oss-release -Dgpg.passphrase="$GPG_PASSPHRASE" release:perform
mvn -Psonatype-oss-release release:clean
