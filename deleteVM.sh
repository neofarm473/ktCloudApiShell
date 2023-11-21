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
projectId=$(echo "$authResponse" | grep -oP '\"project\":{\"domain\":{\"name\":\"Default\",\"id\":\"default\"},\"name\":\"\K.*' | grep -oP '(?<=\",\"id\":\")\w+(?=\"},\"user\":{\"domain\":{\"name\":\")')
echo "projectId: $projectId"

while IFS= read -r line; do
    
#    deleteVMUrl="https://api.ucloudbiz.olleh.com/d1/server/servers/$line"
#    deleteVMResponse=$(curl -X DELETE -H "$XAuthTokenHead" "$deleteVMUrl")
#    echo "deleteVMResponse: $deleteVMResponse"

    deleteVMUrl="https://api.ucloudbiz.olleh.com/d1/server/servers/$line/action"
    deleteVMBody="{
      \"forceDelete\": null
    }"
    deleteVMResponse=$(curl -X POST -H "$XAuthTokenHead" -d "$deleteVMBody" "$deleteVMUrl")
    echo "deleteVMResponse: $deleteVMResponse"

done < deleteVMIPList


