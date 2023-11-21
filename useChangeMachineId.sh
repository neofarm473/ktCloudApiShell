#! /bin/bash

while IFS= read -r line; do
    ssh -i /root/PD-Keypair.pem root@$line "bash -s" < maintainVolume.sh
done < changeMachineIdVMList
