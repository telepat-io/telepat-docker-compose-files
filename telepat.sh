#!/bin/bash
# CLI for Telepat

cat << "EOF"
   __       __                 __ 
  / /____  / /__  ____  ____ _/ /_
 / __/ _ \/ / _ \/ __ \/ __ `/ __/
/ /_/  __/ /  __/ /_/ / /_/ / /_  
\__/\___/_/\___/ .___/\__,_/\__/  
              /_/                 

EOF

red=`tput setaf 1`
green=`tput setaf 2`
cyan=`tput setaf 6`
reset=`tput sgr0`

if hash boot2docker 2>/dev/null; then
  HOSTIP=`boot2docker ip`
  if [[ $HOSTIP == "" ]]
  then
    ENDPOINT="localhost:3000"
    echo "${red}Hello. Seems like you're not running Docker locally, so I've set your API endpoint to 'localhost:3000'. You should probably change that.${reset}"
  else
    HOSTPORT="3000"
    ENDPOINT="$HOSTIP:$HOSTPORT"
    echo "${green}Hello. I've autodetected your API endpoint to be $ENDPOINT. You can always change that."
  fi
else
  ENDPOINT="localhost:3000"
  echo "${green}Hello. I've set your endpoint to 'localhost:3000', but you can always change that.${reset}"
fi

echo -e "\n"
echo "${green}Ok. What can I assist with?${reset}"

while :
do
echo "1. Change Telepat API endpoint"
echo "2. Create a new administrator account"
echo "3. Create a new app"
echo "4. Create a new app with a sample schema"
echo -e "5. Done\n"
read OP
echo -e "\n"

if [[ ! $OP =~ [1-5]+$ ]]
then
  echo -e "${red}Please type one of the numbers in the menu.${reset}"
elif [ $OP -eq 1 ]
then
  echo "${green}Please enter the IP:PORT of your Telepat instance, so I can connect. No 'http://' or trailing slash, please.${reset}"
  read ENDPOINT
  echo -e "$\n{green}Ok, I'll use that. Now what?${reset}\n"
elif [ $OP -eq 2 ]
then
  echo -n "Email: "
  read EMAIL
  echo -n "Password: "
  read PASSWORD
  echo -n "Name: "
  read NAME
  echo -e "\n${cyan}Adding admin account...${reset}\n"

  curl -XPOST $ENDPOINT/admin/add \
    -H "Content-Type: application/json" \
    -d '{ "email": "'$EMAIL'", "password":"'$PASSWORD'", "name":"$NAME"}'

  echo -e "\n${green}Done. Anything else?${reset}"
elif [ $OP -eq 3 ] || [ $OP -eq 4 ]
then
  if [ -z "$EMAIL" ]
  then
    echo -n "Email: "
    read EMAIL
    echo -n "Password: "
    read PASSWORD
  fi
  echo -n "App name: "
  read APP_NAME
  echo -n "API Key: "
  read APIKEY

  if hash sha256sum 2>/dev/null; then
    HASHKEY=`echo -n $APIKEY | sha256sum | cut -d " " -f1`
  else 
    HASHKEY=`echo -n $APIKEY | shasum -a 256 | cut -d " " -f1`
  fi

  echo "${cyan}Logging in...${reset}"
  ADMIN_TOKEN=`curl -s -XPOST $ENDPOINT/admin/login -H "Content-Type: application/json" -d '{ "email": "'$EMAIL'", "password": "'$PASSWORD'"}'  | cut -d'"' -f 4`
  echo "${cyan}Got JWT: $ADMIN_TOKEN${reset}"
  
  echo "${cyan}Adding app...${reset}"
  APP_ID=`curl -s -XPOST $ENDPOINT/admin/app/add \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -d '{ "name": "'$APP_NAME'", "keys": ["'$APIKEY'"]}' | cut -d'"' -f 2`
  echo "${cyan}Created app with ID: $APP_ID${reset}"

  if [ $OP -eq 4 ]
  then
    SCHEMA='{
      "appId": "'$APP_ID'",
      "schema": {
        "comments": {
          "namespace": "comments",
          "type": "comments",
          "properties": {
            "text": {
              "type": "string"
            }
          },
          "belongsTo": [
            {
              "parentModel": "events",
              "relationType": "hasMany"
            }
          ],
          "read_acl": 6,
          "write_acl": 6,
          "meta_read_acl": 6
        },
        "events": {
          "namespace": "events",
          "type": "events",
          "properties": {
            "text": {
              "type": "string"
            },
            "image": {
              "type": "string"
            },
            "options": {
              "type": "object"
            }
          },
          "hasMany": [
            "comments"
          ],
          "read_acl": 7,
          "write_acl": 7,
          "meta_read_acl": 4,
          "icon": "fa-image"
        }
      }
    }'

    echo "${cyan}Updating schema${reset}"
    curl -XPOST $ENDPOINT/admin/schema/update \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -d "$SCHEMA"
    echo ""

    echo "${cyan}Creating context${reset}"
    CTX_ID=`curl -XPOST $ENDPOINT/admin/context/add \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -d '{  "appId": "'$APP_ID'", "name": "Context 1", "state":0 }' | cut -d'"' -f 2`
    echo ""

    echo "${cyan}Adding object${reset}"
    curl -XPOST $ENDPOINT/object/create \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -H "X-BLGREQ-SIGN: $HASHKEY" \
      -H "X-BLGREQ-APPID: $APP_ID" \
      -H "X-BLGREQ-UDID: SEEDING_SCRIPT" \
      -d '{ "model": "events", "context": '$CTX_ID', "content": { "text": "Hello world!" } }'
    echo ""
  fi

  echo -e "\n${green}Done. Anything else?${reset}"
elif [ $OP -eq 5 ]
then
  echo -e "\n${green}Have a nice day!${reset}\n"
  exit
fi
done