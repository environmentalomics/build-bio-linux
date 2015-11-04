#!/bin/sh
# A test script that always fails.

if [ -z "${ROOT:-}" ] ; then
    echo '!'" \$ROOT is not set.  Can't continue"
    exit 1
fi

echo
echo "Epic Fail!!! (ROOT=$ROOT)"

sudo true
false
