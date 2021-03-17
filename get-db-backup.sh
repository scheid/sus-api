#!/usr/bin/env bash


# copy the needed files from remote to local, current directory.
#rsync -avzhe ssh --progress srvadmin@10.132.22.38:/swift-apps/clinical-risk-assessment/backup ./backup


rsync -avzhe ssh --progress srvadmin@10.132.22.38:~/swift-apps/sus-api/backup .
