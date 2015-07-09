#!/bin/bash
#
# Test utils.sh.
#
source $(dirname $0)/utils.sh

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

# Test the elapsed time function.
Str=$(utilsConvertSecondsToHHMMSS 123456)
utilsInfo "Status=$?"
utilsInfo "123456 = $Str"

Str=$(utilsConvertSecondsToHHMMSS 123456x)
utilsInfo "Status=$?"
utilsInfo "123456x = $Str"

# Test max.
Max=$(utilsMax 1 2 3 4 5 6)
utilsInfo "Max=$Max"
utilsAssert "(( $Max == 6 ))"

# Test min.
Min=$(utilsMin 1 2 3 4 5 6)
utilsInfo "Min=$Min"
utilsAssert "(( $Min == 1 ))"

Array=(1 2 3 4 5 6 7)
utilsInfo "Min=$(utilsMin ${Array[@]})"
utilsInfo "Max=$(utilsMax ${Array[@]})"

# utilsExecNoExit
function ex() {
    echo "return code: $1"
    return $1
}
utilsExecNoExit ex 23
utilsInfo "Exit status = $?"
#utilsExec ex 23  # will get a command failed error

utilsExecNoExit ex 1
utilsAssert "(( $? == 0 || $? == 1 || $? == 2 ))"

utilsExecNoExit echo "foo bar" '|' sed -e "'s/bar/spam/'"

# Stack tests.
MyStack=()
utilsStackPush MyStack 1 2 3
utilsInfo "MyStack = ${#MyStack[@]} elements"
echo "MyStack=(${MyStack[@]})"

Top=$(utilsStackTos MyStack)
utilsInfo "Top=$Top"
utilsInfo "MyStack = ${#MyStack[@]} elements"
echo "MyStack=(${MyStack[@]})"

utilsStackPop MyStack Top
utilsInfo "Top=$Top"
utilsInfo "MyStack = ${#MyStack[@]} elements"
echo "MyStack=(${MyStack[@]})"

MyStack=(1 2 3 4)
while (( ${#MyStack[@]} )) ; do
    utilsStackPop MyStack MyTop
    utilsInfo "$MyTop"
done
