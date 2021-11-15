#!/bin/bash

# Setup host
INITIATOR_NAME=$(awk -F= '{print $2}' /etc/iscsi/initiatorname.iscsi)
NAME=$(hostname -s)
IP=10.36.115.12

if [ -z "$INITIATOR_NAME" ] || [ -z "$NAME" ] || [ -z "$IP" ]; then
  echo "INITIATOR_NAME, NAME or IP is empty!" >&2
  exit 1
fi

ssh "3paradm@$IP" createhost -iscsi "$NAME" "$INITIATOR_NAME"

# ---------------------------

RPORTALS=$(ssh "3paradm@$IP" showport -iscsivlans | tail -n+2 | head -n-2 | awk '{print $3}')
LPORTALS=$(sudo iscsiadm -m session -o show | awk -F '[ :,]+' '{print $3}')

# iSCSI login
for RPORTAL in $RPORTALS; do
  for LPORTAL in $LPORTALS; do
    if [ "$LPORTALS" = "$RPORTAL" ]; then
      continue 2
    fi
  done
  sudo iscsiadm -m discovery -t sendtargets -p "$RPORTAL"
  sudo iscsiadm -m node -l all -p "$RPORTAL"
done

# Perform backup
yes | ssh 3paradm@10.36.115.12 removevv prod.one.vm.12701.2.vv-backup
ssh 3paradm@10.36.115.12 createsv -ro -exp 7d prod.one.vm.12701.2.vv-backup prod.one.vm.12701.2.vv
ssh 3paradm@10.36.115.12 createvlun prod.one.vm.12701.2.vv-backup 100 storage10-f181
ssh 3paradm@10.36.115.12 showvv -showcols VV_WWN prod.one.vm.12701.2.vv-backup | awk 'FNR == 2 {print tolower($1)}'
iscsiadm -m session --rescan $RPORTALS
/dev/mapper/3${WWN}
restic blablablah
yes | ssh 3paradm@10.36.115.12 removevlun prod.one.vm.12701.2.vv-backup 100 storage10-f181
yes | ssh 3paradm@10.36.115.12 removevv prod.one.vm.12701.2.vv-backup

iscsiadm -m session --rescan $RPORTALS


# iSCSI logout
#sudo iscsiadm -m session -o show | while read _ _ LPORTAL _; do
#  for RPORTAL in $RPORTALS; do
#    if [ "$LPORTAL" = "$RPORTAL" ]; then
#      sudo iscsiadm --mode node -u -p "$RPORTAL"
#    fi
#  done
#done
