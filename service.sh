#!/system/bin/sh

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != 1 ]; do
    /system/bin/sleep 1s
done

/system/bin/echo "[$(date +%F) $(date +%T)] - Boot Completed" > /data/local/tmp/conscrypt-trustusercerts-log.txt

# Create a separate temp directory, to hold the current certificates
# Otherwise, when we add the mount we can't read the current certs anymore.

mkdir -p -m 700 /data/local/tmp/tmp-ca-copy

# Copy out the existing certificates and the user ones
cp /apex/com.android.conscrypt/cacerts/* /data/local/tmp/tmp-ca-copy/

cp /data/misc/user/0/cacerts-added/* /data/local/tmp/tmp-ca-copy/

# Create the in-memory mount on top of the system certs folder
mount -t tmpfs tmpfs /system/etc/security/cacerts

# Copy the existing certs back into the tmpfs, so we keep trusting them
mv /data/local/tmp/tmp-ca-copy/* /system/etc/security/cacerts/

# Update the perms & selinux context labels
set_perm_recursive /system/etc/security/cacerts root root 644 644 u:object_r:system_file:s0

/system/bin/echo "[$(date +%F) $(date +%T)] - TempFS Created & certs added" >> /data/local/tmp/conscrypt-trustusercerts-log.txt

# Deal with the APEX overrides, which need injecting into each namespace:

# First we get the Zygote process(es), which launch each app
ZYGOTE_PID=$(pidof zygote || true)
ZYGOTE64_PID=$(pidof zygote64 || true)
# N.b. some devices appear to have both!

# Apps inherit the Zygote's mounts at startup, so we inject here to ensure
# all newly started apps will see these certs straight away:
for Z_PID in $ZYGOTE_PID; do
    if [ -n "$Z_PID" ]; then
        /system/bin/nsenter --mount=/proc/$Z_PID/ns/mnt -- /bin/mount --bind /system/etc/security/cacerts /apex/com.android.conscrypt/cacerts
        /system/bin/echo "[$(date +%F) $(date +%T)] - Mounted successfully on Zygote - PID: $Z_PID" >> /data/local/tmp/conscrypt-trustusercerts-log.txt
    fi
done

for Z_PID in $ZYGOTE64_PID; do
    if [ -n "$Z_PID" ]; then
        /system/bin/nsenter --mount=/proc/$Z_PID/ns/mnt -- /bin/mount --bind /system/etc/security/cacerts /apex/com.android.conscrypt/cacerts
        /system/bin/echo "[$(date +%F) $(date +%T)] - Mounted successfully on Zygote - PID: $Z_PID" >> /data/local/tmp/conscrypt-trustusercerts-log.txt
    fi
done

# Then we inject the mount into all already running apps, so they
# too see these CA certs immediately:

# Get the PID of every process whose parent is one of the Zygotes:
APP_PIDS=$(
    echo "$ZYGOTE_PID $ZYGOTE64_PID" | \
    xargs -n1 ps -o 'PID' -P | \
    grep -v PID
)
# Inject into the mount namespace of each of those apps:
for PID in $APP_PIDS; do
    /system/bin/nsenter --mount=/proc/$PID/ns/mnt -- /bin/mount --bind /system/etc/security/cacerts /apex/com.android.conscrypt/cacerts &
done
wait # Launched in parallel - wait for completion here
/system/bin/echo "[$(date +%F) $(date +%T)] - Mounted successfully on running processes" >> /data/local/tmp/conscrypt-trustusercerts-log.txt


# Remove the temporary cert folder
rm -rf /data/local/tmp/tmp-ca-copy
/system/bin/echo "[$(date +%F) $(date +%T)] - Enjoy the HTTPS interception :D" >> /data/local/tmp/conscrypt-trustusercerts-log.txt