#! /bin/bash

id=""
pw=""

authData="{
    \"auth\": {
      \"identity\": {
        \"methods\": [
          \"password\"
        ],
        \"password\": {
          \"user\": {
            \"domain\": {
              \"id\": \"default\"
            },
            \"name\": \"$id\",
            \"password\": \"$pw\"
          }
        }
      },
      \"scope\": {
        \"project\": {
          \"domain\": {
            \"id\": \"default\"
          },
          \"name\": \"$id\"
        }
      }
    }
}"
authUrl='https://api.ucloudbiz.olleh.com/d1/identity/auth/tokens'
authResponse=$(curl -i -X POST -d "$authData" "$authUrl")
#echo "authResponse: $authResponse"
XAuthToken=$(echo "$authResponse" | grep -oP 'X-Subject-Token: \K.*' | sed 's/X-Subject-Token: //')
XAuthTokenHead="X-Auth-Token: $XAuthToken"
echo "XAuthTokenHead: $XAuthTokenHead"

#get VM image list 
#getUrl="https://api.ucloudbiz.olleh.com/d1/image/images" 
#get network tier list 
getUrl="https://api.ucloudbiz.olleh.com/d1/nc/Network"
#get flavor list 
#getUrl="https://api.ucloudbiz.olleh.com/d1/server/flavors/detail"

getResponse=$(curl -X GET -H "$XAuthTokenHead" "$getUrl")
echo "$getResponse"
