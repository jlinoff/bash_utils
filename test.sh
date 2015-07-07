#!/bin/bash
#
# Test utils.sh.
#
source $(dirname -- $0)/utils.sh

# Test debug messages.
utilsDebug 'Test debug'
utilsDebug 'Test debug' 'second line'

# Test info messages.
utilsInfo 'Test info'
utilsInfo 'Test info' 'second line'

# Test warning messages.
utilsWarn 'Test warn'
utilsWarn 'Test warn' 'second line'

# Test error messages in subshells to avoid exiting.
(utilsErr 'Test err')
(utilsErr 'Test err' 'second line')
utilsErrNoExit 'Test err - no exit'

# Test the exec command and configurations.
utilsExec sleep 1
utilsExecPwd=1
utilsExec sleep 1
utilsExecStatus=1
utilsExec sleep 1
utilsExecTime=1
utilsExec sleep 1

# Show that exec works with shell pipes if properly quoted.
utilsExec echo "foo bar" '|' sed -e "s/bar/spam/g"
(utilsAssert [ -f "test_file_exists" ])
(utilsAssert [ -f "$0" ])

# Show that exec works with shell redirection if properly quoted.
TmpFile="/tmp/_utils_test"
utilsExec echo 'test data' '>' "$TmpFile"
utilsExec cat $TmpFile
(utilsAssert [ -f $TmpFile ])
utilsExec rm -f $TmpFile
(utilsAssert [ -f $TmpFile ])
(utilsAssert [ ! -f $TmpFile ])

# Check quoted arguments.
utilsExec echo 'check quoted' 'arguments'
utilsExec sed "'"'s/\(.\)$/\1xxx/'"'" <<< 'foo bar spam'

# Check arithmetic tests.
(utilsAssert "(( 1 == 2 ))" )
utilsAssert "(( 1 == 1 ))"

A1=(1 2 3 4)
for i in $(seq 0 5) ; do
    if utilsArrayContains A1 $i ; then
        echo "A1 contains $i"
    else
        echo "A1 does not contain $i"
    fi
done

if ! utilsArrayContains A1 10 ; then
    echo "A1 does not contain 10"
fi

A1=("foo" "bar" "spam")
for i in "foo" "foobar" "spambar" "spam" ; do
    if utilsArrayContains A1 $i ; then
        echo "A1 contains $i"
    else
        echo "A1 does not contain $i"
    fi
done
