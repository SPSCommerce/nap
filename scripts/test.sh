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
# Test overflow input
#
echo "TEST: Overflow returns exit status 2"
./out/nap-x86-64 234587234857293847582834 1>/dev/null 2>/dev/null
EXIT_CODE=$?
if [[ "$EXIT_CODE" != "2" ]]; then
    STATUS="FAIL"
    echo "FAILED: Expected exit status 2. Got exit status $EXIT_CODE"
else
    echo "PASSED"
fi

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
