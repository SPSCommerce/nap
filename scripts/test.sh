#!/usr/bin/env sh

chmod a+x ./out/nap-x86-64

STATUS="PASS"

#
# Test bad input
#
echo "TEST: Bad input returns exit status 1"
./out/nap-x86-64 1234NOPE 1>/dev/null 2>/dev/null
EXIT_CODE=$?
if [[ "$EXIT_CODE" != "1" ]]; then
    STATUS="FAIL"
    echo "FAILED: Expected exit status 1. Got exit status $EXIT_CODE"
else
    echo "PASSED"
fi

#
# Test overflow inputs
#
for INPUT in 234587234857293847582834 4294967296 6442450943; do
    echo "TEST: Overflow returns exit status 2"
    # NOTE: Incorrect processing of overflow inputs could cause a very
    # long sleep!  Set a timeout on these test cases.
    (
        sleep 12
        PROCS="`ps`"
        if echo "$PROCS" | grep nap-x86-64 >/dev/null; then
            echo 'Timeout!'
            killall nap-x86-64
        fi
    ) &
    ./out/nap-x86-64 $INPUT 1>/dev/null 2>/dev/null
    EXIT_CODE=$?
    if [[ "$EXIT_CODE" != "2" ]]; then
        STATUS="FAIL"
        echo "FAILED: Expected exit status 2. Got exit status $EXIT_CODE"
    else
        echo "PASSED"
    fi
    kill %1 # Terminate the timeout job.
    wait # Reap the exit status before continuing.
done

#
# Test command-line argument
#
echo "TEST: nap pauses for time specified by command-line argument"

# The Time command writes its output to stderr, so we'll capture that in the variable
TIME=$(time -f "%e" ./out/nap-x86-64 3 2>&1 > /dev/null)

# Time will be in format 3.00. Round this to just the seconds.
SECONDS=$(echo "$TIME" | cut -d'.' -f0)
if [[ "$SECONDS" != "3" ]]; then
    STATUS="FAIL"
    echo "FAILED: Expected to wait 3 seconds. Waited $SECONDS seconds"
else
    echo "PASSED"
fi

#
# Test default
#
echo "TEST: nap without command-line argument pauses for default 10 seconds"
TIME=$(time -f "%e" ./out/nap-x86-64 2>&1 > /dev/null)
SECONDS=$(echo "$TIME" | cut -d'.' -f0)
if [[ "$SECONDS" != "10" ]]; then
    STATUS="FAIL"
    echo "FAILED: Expected to wait 10 seconds. Waited $SECONDS seconds"
else
    echo "PASSED"
fi

if [[ "$STATUS" != "PASS" ]]; then
    exit 1
fi

exit 0
