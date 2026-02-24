#!/bin/bash

SG_ID="sg-0ee2f2d6d23635d4e"
AMI_ID="ami-0220d79f3f480ecf5"
DOMAIN_NAME="madsha.online"
HOST_ID="Z057813716AUIKFKUER3B"

for instance in $@
do
    INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
        )
            RECORD_NAME=$DOMAIN_NAME #madsha.online
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )  
        RECORD_NAME="$instance.$DOMAIN_NAME" #mongodb.madsha.online
    fi

echo "IP Address: $IP"
echo "$INSTANCE_ID"

            aws route53 change-resource-record-sets \
            --hosted-zone-id $HOST_ID \
            --change-batch '{
        "Comment": "Updating record ",
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
        }
        '
echo "record updated for $instance "

done    


