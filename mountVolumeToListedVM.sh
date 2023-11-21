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
echo "$XAuthTokenHead"
projectId=$(echo "$authResponse" | grep -oP '\"project\":{\"domain\":{\"name\":\"Default\",\"id\":\"default\"},\"name\":\"\K.*' | grep -oP '(?<=\",\"id\":\")\w+(?=\"},\"user\":{\"domain\":{\"name\":\")')
echo "projectId: $projectId"

while IFS= read -r line; do

    if [ -z "$line" ]; then
        continue
    fi

    echo "$line" >> "mountVolumeToListedVM_log_file"

    line=$(echo $line | tr -s '[:space:]' ';')
    zone=$(echo $line | cut -d';' -f1)
    volumeSize=$(echo $line | cut -d';' -f2)
    billingUnit=$(echo $line | cut -d';' -f3)
    volumeName=$(echo $line | cut -d';' -f4)
    isBootable=$(echo $line | cut -d';' -f5)
    serverId=$(echo $line | cut -d';' -f6)
    mountPath=$(echo $line | cut -d';' -f7)
    snapshotId=$(echo $line | cut -d';' -f8)
    #echo $zone
    #echo $volumeSize
    #echo $billingUnit
    #echo $volumeName
    #echo $isBootable
    #echo $serverId
    #echo $mountPath
    #echo $snapshotId

    createVolumeUrl="https://api.ucloudbiz.olleh.com/d1/volume/$projectId/volumes"
    current_time=$(date +"%Y-%m-%d %H:%M:%S")
    createVolumeBody="{
      \"volume\": {
        \"availability_zone\": \"$zone\",
        \"size\": $volumeSize,
        \"usage_plan_type\": \"$billingUnit\",
        \"name\": \"$volumeName\",
        \"bootable\": $isBootable,
      }
    }"

    createVolumeBody2="{
      \"volume\": {
        \"availability_zone\": \"$zone\",
        \"size\": $volumeSize,
        \"usage_plan_type\": \"$billingUnit\",
        \"name\": \"$volumeName\",
        \"bootable\": $isBootable,
        \"snapshot_id\": "$snapshotId"
      }
    }"
    echo "snapshotId: $snapshotId"
    if [ -z "$snapshotId" ]; then
      echo "createVolumeBody: $createVolumeBody" >> "mountVolumeToListedVM_log_file"
      createVolumeResponse=$(curl -X POST -H "$XAuthTokenHead" -d "$createVolumeBody" "$createVolumeUrl")
    else
      echo "createVolumeBody: $createVolumeBody2" >> "mountVolumeToListedVM_log_file"
      createVolumeResponse=$(curl -X POST -H "$XAuthTokenHead" -d "$createVolumeBody2" "$createVolumeUrl")
    fi

    volumeId=$(echo "$createVolumeResponse" | grep -oP '(?<={"volume": {"id": ")[\w-]+')
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp]" >> "mountVolumeToListedVM_log_file"
    echo "volumeId: $volumeId"
    echo "volumeId: $volumeId" >> "mountVolumeToListedVM_log_file"
    #echo "createVolumeResponse: $createVolumeResponse"
    echo "$createVolumeResponse" >> "mountVolumeToListedVM_log_file"

    volumeAttachmentUrl="https://api.ucloudbiz.olleh.com/d1/server/servers/$serverId/os-volume_attachments"
    volumeAttachmentBody="{
      \"volumeAttachment\": {
        \"volumeId\": \"$volumeId\",
        \"device\": \"$mountPath\"
      }
    }"
    
    echo "volumeAttachmentUrl: $volumeAttachmentUrl" >> "mountVolumeToListedVM_log_file"
    echo "volumeAttachmentBody: $volumeAttachmentBody" >> "mountVolumeToListedVM_log_file"

    count=0
    volumeAttachmentTry=20
    while true; do
        getVolumeUrl="https://api.ucloudbiz.olleh.com/d1/volume/$projectId/volumes/$volumeId"
        getVolumeResponse=$(curl -X GET -H "$XAuthTokenHead" "$getVolumeUrl")
        echo "getVolumeResponse: $getVolumeResponse" >> "mountVolumeToListedVM_log_file"

        # "attachments": [],
        if ! echo "$getVolumeResponse" | grep -q "\"attachments\": \[\],"; then
            echo "volumeAttachment successed"
            echo "volumeAttachment successed" >> "mountVolumeToListedVM_log_file"
            break
        fi

        ((count++))
        echo "volumeAttachmentTry: [[ $count/$volumeAttachmentTry ]]"
        echo "volumeAttachmentTry: [[ $count/$volumeAttachmentTry ]]" >> "mountVolumeToListedVM_log_file"

        volumeAttachmentResponse=$(curl -X POST -H "$XAuthTokenHead" -d "$volumeAttachmentBody" "$volumeAttachmentUrl")
        echo "$volumeAttachmentResponse" >> "mountVolumeToListedVM_log_file"
        
        if [[ ! count -lt $volumeAttachmentTry ]] || [[ $volumeAttachmentResponse == *"itemNotFound"* ]]; then
          echo "volumeAttachment failed"
          echo "delete volume"
          echo "volumeAttachment failed" >> "mountVolumeToListedVM_log_file"
          echo "delete volume" >> "mountVolumeToListedVM_log_file"

          deleteVolumeUrl="https://api.ucloudbiz.olleh.com/d1/volume/$projectId/volumes/$volumeId"
          deleteVolumeResponse=$(curl -X DELETE -H "$XAuthTokenHead" "$deleteVolumeUrl")
          echo "deleteVolumeResponse: $deleteVolumeResponse"
          echo "deleteVolumeResponse: $deleteVolumeResponse" >> "mountVolumeToListedVM_log_file"
          break
        fi
                
    done


done < VMMountList
