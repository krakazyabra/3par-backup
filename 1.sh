#!/bin/bash
IP=$1
PATTERN=$2

if [ -z "$PATTERN" ]; then
  "Usage: $0 <3par> <pattern>"
  exit 1
fi

# Setup host
INITIATOR_NAME=$(awk -F= '{print $2}' /etc/iscsi/initiatorname.iscsi)
HOST=$(hostname -s)

if [ -z "$INITIATOR_NAME" ] || [ -z "$HOST" ] || [ -z "$IP" ]; then
  echo "INITIATOR_NAME, HOST or IP is empty!" >&2
  exit 1
fi

ssh "3paradm@$IP" createhost -iscsi "$HOST" "$INITIATOR_NAME"

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

VVS=$(ssh "3paradm@$IP" showvv -showcols Name "$PATTERN" | head -n-2 | tail -n+2)

# Perform backup
for VV in $VVS; do
  (
    LUN=99
    iscsiadm -m session --rescan "$RPORTALS"
    ISCSI_DISKS=$(iscsiadm -m session -P3 | grep "Lun: $LUN$" -A1 | awk '/Attached scsi disk/ {print $4}')

    OLD_VV=$(ssh "3paradm@$IP" showvlun -host "$HOST" | awk "\$1 == $LUN && \$NF == \"host\" {print \$2}" )
    if [ -n "$OLD_VV" ]; then
      yes | ssh "3paradm@$IP" removevlun "$OLD_VV" "$LUN" "$HOST"
    fi

    # cleanup broken devices (just in case)
    for device in ${ISCSI_DISKS}; do
      if [ -e /dev/${device} ] && ! fdisk -l /dev/${device} >/dev/null 2>&1; then
        blockdev --flushbufs /dev/${device}
        echo 1 > /sys/block/${device}/device/delete
      fi
    done

    yes | ssh "3paradm@$IP" removevv "$VV-backup" 2>/dev/null

    # attach
    yes | ssh "3paradm@$IP" createsv -ro -exp 7d "$VV-backup" "$VV"
    yes | ssh "3paradm@$IP" createvlun "$VV-backup" "$LUN" "$HOST"
    WWN=$(ssh "3paradm@$IP" showvv -showcols VV_WWN "$VV-backup" | awk 'FNR == 2 {print tolower($1)}')
    iscsiadm -m session --rescan "$RPORTALS"
    ISCSI_DISKS=$(iscsiadm -m session -P3 | grep "Lun: $LUN$" -A1 | awk '/Attached scsi disk/ {print $4}')
    multipath $ISCSI_DISKS
    DM_HOLDER=$(dmsetup ls -o blkdevname | awk "\$1 == \"3$WWN\" {gsub(/[()]/,\"\");print \$2}")
    DM_SLAVE=$(ls -1 /sys/block/${DM_HOLDER}/slaves)

    echo Processing $VV-backup
    (
      set -x
      dd if="/dev/$DM_HOLDER" of=/dev/null status=progress
    )

    # detach
    multipath -f "3${WWN}"
    unset device
    for device in ${DM_SLAVE}; do
      if [ -e /dev/${device} ]; then
          blockdev --flushbufs /dev/${device}
          echo 1 > /sys/block/${device}/device/delete
      fi
    done

    yes | ssh "3paradm@$IP" removevlun "$VV-backup" "$LUN" "$HOST"
    yes | ssh "3paradm@$IP" removevv "$VV-backup"
  )
done

iscsiadm -m session --rescan $RPORTALS

# iSCSI logout
sudo iscsiadm -m session -o show | while read _ _ LPORTAL _; do
  for RPORTAL in $RPORTALS; do
    if [ "$LPORTAL" = "$RPORTAL" ]; then
      sudo iscsiadm --mode node -u -p "$RPORTAL"
    fi
  done
done

ssh "3paradm@$IP" removehost "$HOST"
root@storage10-f181:~# cat /tmp/1.sh
#!/bin/bash
IP=$1
PATTERN=$2

if [ -z "$PATTERN" ]; then
  "Usage: $0 <3par> <pattern>"
  exit 1
fi

# Setup host
INITIATOR_NAME=$(awk -F= '{print $2}' /etc/iscsi/initiatorname.iscsi)
HOST=$(hostname -s)

if [ -z "$INITIATOR_NAME" ] || [ -z "$HOST" ] || [ -z "$IP" ]; then
  echo "INITIATOR_NAME, HOST or IP is empty!" >&2
  exit 1
fi

ssh "3paradm@$IP" createhost -iscsi "$HOST" "$INITIATOR_NAME"

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

VVS=$(ssh "3paradm@$IP" showvv -showcols Name "$PATTERN" | head -n-2 | tail -n+2)

# Perform backup
for VV in $VVS; do
  (
    LUN=99
    iscsiadm -m session --rescan "$RPORTALS"
    ISCSI_DISKS=$(iscsiadm -m session -P3 | grep "Lun: $LUN$" -A1 | awk '/Attached scsi disk/ {print $4}')

    OLD_VV=$(ssh "3paradm@$IP" showvlun -host "$HOST" | awk "\$1 == $LUN && \$NF == \"host\" {print \$2}" )
    if [ -n "$OLD_VV" ]; then
      yes | ssh "3paradm@$IP" removevlun "$OLD_VV" "$LUN" "$HOST"
    fi

    # cleanup broken devices (just in case)
    for device in ${ISCSI_DISKS}; do
      if [ -e /dev/${device} ] && ! fdisk -l /dev/${device} >/dev/null 2>&1; then
        blockdev --flushbufs /dev/${device}
        echo 1 > /sys/block/${device}/device/delete
      fi
    done

    yes | ssh "3paradm@$IP" removevv "$VV-backup" 2>/dev/null

    # attach
    yes | ssh "3paradm@$IP" createsv -ro -exp 7d "$VV-backup" "$VV"
    yes | ssh "3paradm@$IP" createvlun "$VV-backup" "$LUN" "$HOST"
    WWN=$(ssh "3paradm@$IP" showvv -showcols VV_WWN "$VV-backup" | awk 'FNR == 2 {print tolower($1)}')
    iscsiadm -m session --rescan "$RPORTALS"
    ISCSI_DISKS=$(iscsiadm -m session -P3 | grep "Lun: $LUN$" -A1 | awk '/Attached scsi disk/ {print $4}')
    multipath $ISCSI_DISKS
    DM_HOLDER=$(dmsetup ls -o blkdevname | awk "\$1 == \"3$WWN\" {gsub(/[()]/,\"\");print \$2}")
    DM_SLAVE=$(ls -1 /sys/block/${DM_HOLDER}/slaves)

    echo Processing $VV-backup
    (
      set -x
      dd if="/dev/$DM_HOLDER" of=/dev/null status=progress
    )

    # detach
    multipath -f "3${WWN}"
    unset device
    for device in ${DM_SLAVE}; do
      if [ -e /dev/${device} ]; then
          blockdev --flushbufs /dev/${device}
          echo 1 > /sys/block/${device}/device/delete
      fi
    done

    yes | ssh "3paradm@$IP" removevlun "$VV-backup" "$LUN" "$HOST"
    yes | ssh "3paradm@$IP" removevv "$VV-backup"
  )
done

iscsiadm -m session --rescan $RPORTALS

# iSCSI logout
sudo iscsiadm -m session -o show | while read _ _ LPORTAL _; do
  for RPORTAL in $RPORTALS; do
    if [ "$LPORTAL" = "$RPORTAL" ]; then
      sudo iscsiadm --mode node -u -p "$RPORTAL"
    fi
  done
done

ssh "3paradm@$IP" removehost "$HOST"
