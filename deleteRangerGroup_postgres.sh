#!/bin/bash
## Script to delete Ranger Groups from Postgres database
## Usage: deleteRangerGroup_postgres.sh -f input.txt -u ranger_user -p password -db ranger [-r <replaceUser>]
##    -f       contains newline separated list of groups to be deleted
##    -u       db user name
##    -p       db user password
##    -db      db name
##    -r       (optional) User to be used to replace references of deleted user. If not provided, `admin` will be used.

usage() {
  [ "$*" ] && echo "$0: $*"
  sed -n '/^##/,/^$/s/^## \{0,1\}//p' "$0"
  exit 2
} 2>/dev/null


while [ "$1" != "" ]; do
    case $1 in
        -f | --file )           shift
                                filename=$1
                                ;;
        -u | --username )		shift
								user=$1
                                ;;
        -p | --password )		shift
								passwd=$1
                                ;;
        -r | --replaceUser )	shift
								superuser=$1
                                ;;
        -db | --db )            shift
								dbname=$1
								;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [ -z "$filename" ];	then	usage; exit 1; fi 
if [ -z "$user" ];		then	usage; exit 1; fi 
if [ -z "$passwd" ];	then	usage; exit 1; fi 
if [ -z "$dbname" ];	then	usage; exit 1; fi 

export PGPASSWORD=${passwd}
mysqlex="/usr/bin/psql -U ${user} -d $dbname"

$mysqlex -f ./grp_proc.psql

while read line
do
    name=$(echo $line)
	if [ -z "$name" ]; then	continue; fi
		name=$(echo "$name" | sed "s|\\\0|\\\\\\0|g")
		name=$(echo "$name" | sed "s|'|\\\'|g")
		name=$(echo "$name" | sed "s|%|\\\%|g")
		name=$(echo "$name" | sed "s|\\\_|\\\\\\\_|g")
		name=$(echo "$name" | sed "s|Z|\\\Z|g")
    echo "  Deleting group : $name"
    $mysqlex -c "SELECT deleteGroupByGroupName('$name')"
done < $filename

$mysqlex -c "DROP FUNCTION IF EXISTS deleteGroupByGroupName(grpName varchar(1024))"

echo "Deleted all Groups successfully"
