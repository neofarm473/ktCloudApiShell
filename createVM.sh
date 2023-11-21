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

    if [ -z "$line" ]; then
        continue
    fi

    echo "$line" >> "createVM_log_file"

    line=$(echo $line | tr -s '[:space:]' ';')
    serverName=$(echo $line | cut -d';' -f1)
    keypair=$(echo $line | cut -d';' -f2)
    flavorName=$(echo $line | cut -d';' -f3)
    zone=$(echo $line | cut -d';' -f4)
    networkTierName=$(echo $line | cut -d';' -f5)
    block_device_mapping_v2_volumeSize=$(echo $line | cut -d';' -f6)
    installOSImageId=$(echo $line | cut -d';' -f7)
    fixedIP=$(echo $line | cut -d';' -f8)

    #echo "flavorName: $flavorName"
    getFlavorListUrl="https://api.ucloudbiz.olleh.com/d1/server/flavors/detail"
    flavorListResponse=$(curl -X GET -H "$XAuthTokenHead" "$getFlavorListUrl")
    #echo "flavorListResponse: $flavorListResponse"
    flavorId=$(echo "$flavorListResponse" | grep -oP "[\w-]+(?=\", \"name\": \"$flavorName\")")
    #echo "flavorId: $flavorId"

    #echo "networkTierName: $networkTierName"
    getNetworkTierListUrl="https://api.ucloudbiz.olleh.com/d1/nc/Network"
    networkTierListResponse=$(curl -X GET -H "$XAuthTokenHead" "$getNetworkTierListUrl")
    #echo "networkTierListResponse: $networkTierListResponse"
    networkTierOSNetworkId=$(echo "$networkTierListResponse" | grep -oP "(?<=\"name\":\"$networkTierName\",\"zoneid\":\"DX-M1\",\"datalakeyn\":\").+" | sed -n 's/status.*/status/p' | sed -n 's/.*osnetworkid/osnetworkid/p' | grep -oP '(?<=osnetworkid\":\")[\w-]+(?=\",\"status)')
    #echo "networkTierOSNetworkId: $networkTierOSNetworkId"

    #echo $serverName
    #echo $keypair
    #echo $flavorId
    #echo $zone
    #echo $networkTierOSNetworkId
    #echo $block_device_mapping_v2_volumeSize
    #echo $installOSImageId
    #echo $fixedIP

    createVMUrl="https://api.ucloudbiz.olleh.com/d1/server/servers"
    createVMBody="{
      \"server\": {
        \"name\": \"$serverName\",
        \"key_name\": \"$keypair\",
        \"flavorRef\": \"$flavorId\",
        \"availability_zone\": \"$zone\",
        \"networks\": [
          {
            \"uuid\": \"$networkTierOSNetworkId\",
            \"fixed_ip\": \"$fixedIP\"
          }
        ],
        \"block_device_mapping_v2\": [
          {
            \"destination_type\": \"volume\",
            \"boot_index\": \"0\",
            \"source_type\": \"image\",
            \"volume_size\": $block_device_mapping_v2_volumeSize,
            \"uuid\": \"$installOSImageId\"
          }
        ]
      }
    }"

    createVMBody2="{
      \"server\": {
        \"name\": \"$serverName\",
        \"key_name\": \"$keypair\",
        \"flavorRef\": \"$flavorId\",
        \"availability_zone\": \"$zone\",
        \"networks\": [
          {
            \"uuid\": \"$networkTierOSNetworkId\"
          }
        ],
        \"block_device_mapping_v2\": [
          {
            \"destination_type\": \"volume\",
            \"boot_index\": \"0\",
            \"source_type\": \"image\",
            \"volume_size\": $block_device_mapping_v2_volumeSize,
            \"uuid\": \"$installOSImageId\"
          }
        ]
      }
    }"

    if [ -z "$fixedIP" ]; then
      createVMResponse=$(curl -X POST -H "$XAuthTokenHead" -d "$createVMBody2" "$createVMUrl")
      echo "createVMBody: $createVMBody2" >> "createVM_log_file"
    else
      createVMResponse=$(curl -X POST -H "$XAuthTokenHead" -d "$createVMBody" "$createVMUrl")
      echo "createVMBody: $createVMBody" >> "createVM_log_file"
    fi
    echo "createVMResponse: $createVMResponse"

    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp]" >> "createVM_log_file"
    echo "$createVMResponse" >> "createVM_log_file"

done < VMParameterList
