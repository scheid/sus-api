#!/usr/bin/env bash

mkdir -p ./backup

#timestamp=`date +"%s"`
timestamp=`date +%d-%b-%Y_%H-%M-%S`

cp ./sus-scores.sqlite ./backup/sus-scores_backup_${timestamp}.sqlite
