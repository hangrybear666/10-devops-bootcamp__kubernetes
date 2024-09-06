#!/bin/bash

# extract the current directory name from pwd command (everything behind the last backslash
CURRENT_DIR=$(pwd | sed 's:.*/::')
if [ "$CURRENT_DIR" != "scripts" ]
then
  echo "please change directory to scripts folder and execute the shell script again."
  exit 1
fi

RANDOM_PASSWORD=$(openssl rand -base64 12)
RANDOM_ROOT_PASSWORD=$(openssl rand -base64 12)

cd ../java-app/
touch .env
echo "# MYSQL INSTALLATION
MYSQL_ROOT_PASSWORD=$RANDOM_ROOT_PASSWORD
MYSQL_DATABASE=team-member-projects
MYSQL_USER=mysql-user
MYSQL_PASSWORD=$RANDOM_PASSWORD
# JAVA-APPLICATION
DB_USER=mysql-user
DB_SERVER=mysqldb
DB_NAME=team-member-projects
DB_PWD=$RANDOM_PASSWORD" > .env

echo "Created .env file with secrets in java-app/ folder.
--------------------------------"
cat .env