#!/bin/bash

# This is a collection of general purpose bash functions for handling
# certain low level functions like messages, assertions and command
# monitoring. The available commands are:
#
#   utilsArrayContains           Is element in array.
#   utilsAssert                  Do an assertion test.
#   utilsConvertSecondsToHHMMSS  Convert seconds to HH:MM:SS format.
#   utilsDebug                   Prints a debug message.
#   utilsErr                     Prints an error message and exits.
#   utilsErrNoExit               Prints an error message but does not exit.
#   utilsExec                    Execute a command with options for exiting on error.
#   utilsExecNoExit              Execute a command with options, do not exit.
#   utilsInfo                    Prints an information message.
#   utilsMax                     Get the maximum value.
#   utilsMin                     Get the minimum value.
#   utilsMkdirs                  Make multiple directories.
#   utilsStackPush               Push onto a stack.
#   utilsStackTos                Report the top of stack.
#   utilsStackPop                Pop off the top of the stack.
#   utilsWarn                    Prints a warning message.
#
# Here are some example usages:
#
#   utilsInfo 'this is a message'
#   utilsErr  'will exit'
#   utilsErrNoExt 'will not exit'
#   utilsAssert [ -f foo.bar ]  # exits if file foo.bar does not exist.
#   utilsAssert "(( $num1 < $num2 ))"  # exits if $num1 >= $num2
#
#   utilsExec ls -1
#   utilsExecNoExit e2fsck -p -f /dev/mapper/${LOOP_DEVICE}p1
#   utilsAssert "(( $? == 0 || $? == 1 ))"
#
# utilsExec is especially useful to scripts where you need to check
# the resuls of some commands and exit if they fail, and you need to
# know where in the source code that the command was executed.
#
#   utilsExec mount this on_that  # this must work
#
# These are the global variables that control the operation of the
# utilities.
#
#   Global Variable      Def Description
#   ==================== === =======================================
#   utilsDebugEnable      1  enable/disable utilsDebug (DEBUG) messages
#   utilsErrEnable        1  enable/disable utilsErr (ERROR) messages
#   utilsErrExitCode      1  default utilsErr exit code
#   utilsErrNoExitEnable  1  enable/disable utilsErrNoExit (ERROR) messages
#   utilsExecExitOnError  1  enable/disable exit on error for utilsExec (same as utilsExecNoExit)
#   utilsExecCmd          1  enable/disable utilsExec cmd reporting
#   utilsExecPwd          0  enable/disable utilsExec pwd reporting
#   utilsExecTime         0  enable/disable utilsExec cmd timing
#   utilsExecStatus       0  enable/disable utilsExec cmd status report
#   utilsInfoEnable       1  enable/disable utilsInfo (INFO) messages
#   utilsMsgEnable        1  enable/disable all messages
#   utilsWarnEnable       1  enable/disable utilsWarn (WARNING) messages
#
#   0=disabled, 1=enabled
#
# The message format can be defined by setting utilsMsgPrefixFormat
# using the available field types. The field types available are:
#
#   %date     current date: %Y-%m-%d
#   %datetime timestamp %Y-%m-%d %H:%M%S
#   %file     the caller file name
#   %filebase the file base name
#   %func     the caller function name
#   %line     the caller line number
#   %time     current time: %H:%M:%S
#   %type     message type: INFO, ERROR, WARNING, DEBUG
#
# The default setting is:
#
#   utilsMsgPrefixFormat='%date %time %type %filebase %line '
#

# LICENSE
#   
# Copyright (c) 2015 Joe Linoff
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Module variables that dictate message processing.
# enable=1, disable=0
utilsDebugEnable=1      # enable/disable utilsDebug (DEBUG) messages
utilsErrEnable=1        # enable/disable utilsErr (ERROR) messages
utilsErrExitCode=1      # default utilsErr exit code
utilsErrNoExitEnable=1  # enable/disable utilsErrNoExit (ERROR) messages
utilsExecExitOnError=1  # enable/disable exit on error for utilsExec
utilsExecCmd=1          # enable/disable utilsExec cmd reporting
utilsExecPwd=0          # enable/disable utilsExec pwd reporting
utilsExecTime=0         # enable/disable utilsExec cmd timing
utilsExecStatus=0       # enable/disable utilsExec cmd status report
utilsInfoEnable=1       # enable/disable utilsInfo (INFO) messages
utilsMsgEnable=1        # enable/disable all messages
utilsWarnEnable=1       # enable/disable utilsWarn (WARNING) messages

utilsMsgPrefixFormat='%date %time %type %filebase %line '

# Check the version number.
function utilsCheckVersion() {
    local Context=($(caller 0))
    local Lineno=${Context[0]}
    local Funcname=${Context[1]}
    local FileName=${Context[2]}

    # First check the version number.
    if (( ${BASH_VERSINFO[0]} < 4 )) ; then
        echo "ERROR:${Filename}:${Lineno}: Sorry you need at least bash version 4.0 to run this script."
        exit 1
    fi
}

utilsCheckVersion

# Get contextual prefix.
function utilsMsgGetPrefix() {
    local Type="$1"

    # Find the correct level by ignoring functions with a '_' prefix.
    # This is the line number in the callers source code.
    local Level=0
    local Regex1='^utils[A-Z]'
    for FuncName in ${FUNCNAME[@]} ; do
        if [[ ! ${FuncName} =~ ${Regex1} ]] ; then
            break
        fi
        Level=$(( $Level + 1 ))
    done
    
    # Now determine the caller.
    Level=$(( $Level - 1 ))
    local Lineno=$(caller $Level | awk '{print $1;}')
    local Funcname=$(caller $Level | awk '{print $2;}')
    local Filename=$(caller $Level | awk '{print $3;}')
    local BaseFilename=$(basename "$Filename")

    # Get date/time stamps.
    local Date=$(date +'%Y-%m-%d')
    local Time=$(date +'%H:%M:%S.%N')
    local Datetime="$Date $Time"

    # Define the prefix.
    local Prefix=$(sed \
        -e "s/%line/$Lineno/g" \
        -e "s@%filebase@$BaseFilename@" \
        -e "s@%file@$Filename@" \
        -e "s/%func/$Funcname/" \
        -e "s/%datetime/$Datetime/" \
        -e "s/%date/$Date/" \
        -e "s/%time/$Time/" \
        -e "s/%type/$Type/" \
        <<< "$utilsMsgPrefixFormat")
    echo "$Prefix"
    return 0
}

# Print a message.
function utilsMsg() {
    local Type="$1"
    shift

    # See if messages are enabled.
    local VarName="${FUNCNAME[1]}Enable"
    local VarVal=$(eval echo \$$VarName)
    if (( $VarVal )) && (( $utilsMsgEnable )); then
        local Prefix="$(utilsMsgGetPrefix $Type)"
        for Line in "$@" ; do
            printf '%s%s\n' "$Prefix" "$Line"
            Prefix=$(printf '%*s' ${#Prefix} ' ')
        done
    fi
}

# Print an error message and exit
# Multiple arguments are printed on different lines.
# Use introspection to get the line number of the caller.
# Usage: utilsErr 'something bad happened'
function utilsErr() {
    utilsMsg ERROR "$@"
    exit $utilsErrExitCode
}

# Print an error message but don't exit
# Multiple arguments are printed on different lines.
# Use introspection to get the line number of the caller.
# Usage: utilsErr 'something bad happened'
function utilsErrNoExit() {
    utilsMsg ERROR "$@"
}

# Print a warning message and exit
# Multiple arguments are printed on different lines.
# Use introspection to get the line number of the caller.
# Usage: utilsWarn 'something sort of bad happened' 'this is what it was'
function utilsWarn() {
    utilsMsg WARNING "$@"
}

# Print an information message.
# Multiple arguments are printed on different lines.
# Use introspection to get the line number of the caller.
# Usage: utilsInfo 'something happened'
function utilsInfo() {
    utilsMsg INFO "$@"
}

# Print a debug message.
# Multiple arguments are printed on different lines.
# Use introspection to get the line number of the caller.
# Usage: utilsDebug 'something should have happened'
function utilsDebug() {
    utilsMsg DEBUG "$@"
}

# Execute a command, check the exit status and exit on error.
# Make sure that arguments are properly quoted, if necessary.
# if utilsExecTime is 1, then time the command.
# if utilsExecCmd is 1, then print the command.
# if utilsExecPwd is 1, then print the current directory.
# if utilsExecStatus is 1, then print the command exit status.
# Usage: utilsExec run this command 'with these' arguments
function utilsExec() {
    # Quote arguments that need quoting.
    local Cmd=''
    local Prog=''
    for Arg in "$@" ; do
        if [[ "$Prog" == "" ]] ; then
            Prog="$Arg"
        fi
        if grep -q '[[:space:]]' <<< "$Arg" ; then
            Cmd="$Cmd \"$Arg\""
        else
            Cmd="$Cmd $Arg"
        fi
    done
    Cmd=${Cmd:1}  # strip off the leading space

    # Print the cmd information.
    if (( $utilsExecCmd )) ; then
        utilsInfo "Cmd: $Cmd"
    fi
    if (( $utilsExecPwd )) ; then
        utilsInfo "Cmd Pwd: $(pwd)"
    fi

    # Execute the command and capture the status.
    if (( $utilsExecTime )) ; then
        local ProgPath=$(type -p "$Prog")  # look for bash built-ins
        if [[ "$ProgPath" == "" ]] ; then
            eval $Cmd
        else
            # This is not a built in bash command, add the timer.
            local Prefix="$(utilsMsgGetPrefix 'INFO')"
            local TimeFormat="${Prefix}Cmd Time: elapsed=%E, user=%U, sys=%S, mem=%M, in=%I, out=%O"
            eval "/usr/bin/time -f '$TimeFormat' $Cmd"
        fi
    else
        eval $Cmd
    fi
    local Status=$?
    if (( $utilsExecStatus )) ; then
        utilsInfo "Cmd Status: $Status"
    fi
    
    if (( $Status )) ; then
        if (( $utilsExecExitOnError )) ; then
            utilsErr "Command failed with exit status ${Status}: $Cmd"
        else
            utilsWarn "Command failed with exit status ${Status}: $Cmd"
        fi
    fi
    return $Status
}

# Execute a command, check the exit status, do not exit on error.
# Make sure that arguments are properly quoted, if necessary.
# if utilsExecTime is 1, then time the command.
# if utilsExecCmd is 1, then print the command.
# if utilsExecPwd is 1, then print the current directory.
# if utilsExecStatus is 1, then print the command exit status.
# Usage:
#    utilsExecNoExit run this command 'with these' arguments
#    utilsAssert (( $? == 0 && $? == 1 ))
function utilsExecNoExit() {
    # Quote arguments that need quoting.
    local Cmd=''
    local Prog=''
    for Arg in "$@" ; do
        if [[ "$Prog" == "" ]] ; then
            Prog="$Arg"
        fi
        if grep -q '[[:space:]]' <<< "$Arg" ; then
            Cmd="$Cmd \"$Arg\""
        else
            Cmd="$Cmd $Arg"
        fi
    done
    Cmd=${Cmd:1}  # strip off the leading space

    # Print the cmd information.
    if (( $utilsExecCmd )) ; then
        utilsInfo "Cmd: $Cmd"
    fi
    if (( $utilsExecPwd )) ; then
        utilsInfo "Cmd Pwd: $(pwd)"
    fi

    # Execute the command and capture the status.
    if (( $utilsExecTime )) ; then
        local ProgPath=$(type -p "$Prog")  # look for bash built-ins
        if [[ "$ProgPath" == "" ]] ; then
            eval $Cmd
        else
            # This is not a built in bash command, add the timer.
            local Prefix="$(utilsMsgGetPrefix 'INFO')"
            local TimeFormat="${Prefix}Cmd Time: elapsed=%E, user=%U, sys=%S, mem=%M, in=%I, out=%O"
            eval "/usr/bin/time -f '$TimeFormat' $Cmd"
        fi
    else
        eval $Cmd
    fi
    local Status=$?
    if (( $utilsExecStatus )) ; then
        utilsInfo "Cmd Status: $Status"
    fi
    
    return $Status
}

# Make one or more directories.
# Usage: utilsMkdirs path1 /pa/th/2 /p/a/t/h/3
function utilsMkdirs() {
    for Dir in "$@" ; do
        [ ! -d "$Dir" ] && mkdir -p "$Dir"
    done
}

# Assert a relationship between two values.
# Exit with an error if they don't match.
# Usage: utilsAssert "(( 1 == 2 ))"
#        utilsAssert "[[ ! 'aa' == 'bb' ]]"
function utilsAssert() {
    local Cmp="$*"
    eval "$Cmp"
    local Status=$?
    if (( $Status )) ; then
        utilsErr "Assertion failed: $Cmp."
    fi
}

# Determine whether an element is contained in an array.
# The first argument is the array variable name.
# The second argument is the element to search for.
# Here is an example usage:
#   A1=(1 2 3 4 5 6)
#   if utilsArrayContains A1 5 ; then
#       echo "A1 contains 5"
#   else
#       echo "A1 does not contain 5"
#   fi
function utilsArrayContains() {
    local ArrayVarName="$1"
    local Element="$2"
    local Array="$ArrayVarName[@]"
    for ArrayElement in ${!Array}; do
        [[ "$ArrayElement" == "$Element" ]] && return 0
    done
    return 1
}

# Convert total seconds to hours, minutes and seconds.
# Usage:
#   Str=$(utilsConvertSecondsToHHMMSS 12345)
#   echo $Str  # s/b 34:17:36
function utilsConvertSecondsToHHMMSS() {
    local TotalSeconds="$1"

    # Verify the arg.
    local Regex='^[0-9]+$'
    if [[ ! "$TotalSeconds" =~ $Regex ]] ; then
        echo "$1"
        return 1
    fi

    # Convert.
    local Hours=$(( $TotalSeconds / 3600 ))
    local Minutes=$(( ( $TotalSeconds % 3600 ) / 60 ))
    local Seconds=$(( $TotalSeconds % 60 ))

    printf '%02d:%02d:%02d' $Hours $Minutes $Seconds
    return 0
}

# Report the max integer in the arg list.
# Usage:
#    Max=$(utilsMax 1 2 3 4 5 6)
#    echo $Max     # 6
function utilsMax() {
    local Max=$1
    shift
    for Num in "$@" ; do
        #Max=$( (( $Max > $Num )) && echo $Max || echo $Num )
        if (( $Num > $Max )) ; then
            Max=$Num
        fi
    done
    echo $Max
    return 0
}

# Report the min integer in the arg list.
# Usage:
#    Min=$(utilsMin 1 2 3 4 5 6)
#    echo $Min     # 1
function utilsMin() {
    local Min=$1
    shift
    for Num in "$@" ; do
        #Min=$( (( $Min < $Num )) && echo $Min || echo $Num )
        if (( $Num < $Min )) ; then
            Min=$Num
        fi
    done
    echo $Min
    return 0
}

# Push onto a stack.
# Usage:
#   MyStack=()
#   utilsStackPush MyStack "value"
function utilsStackPush() {
    local StackVarName="$1"
    shift
    for Elem in "$@" ; do
        eval "$StackVarName+=('$Elem')"
    done
}

# Pop off of a stack.
# Usage:
#   MyStack=()
#   utilsStackPush MyStack 1 2 3
#   utilsStackPop MyStack Top
#   echo $Top             # == 3
#   echo ${#MyStack[@]}   # == 2
function utilsStackPop() {
    local StackVarName="$1"
    local ResultVarName="$2"
    local Size=$(eval echo "\${#${StackVarName}[@]}")
    if (( $Size > 0 )) ; then
        local Last=$(( $Size - 1 ))
        local Top=$(eval echo "\${${StackVarName}[${Last}]}")
        eval unset "${StackVarName}[${Last}]"
        eval "${ResultVarName}=${Top}"
    fi
    return 0
}

# Get the value at the top of the stack.
# Usage:
#   MyStack=()
#   utilsStackPush MyStack 1 2 3
#   Elem=$(utilsStackTos MyStack)
function utilsStackTos() {
    local StackVarName="$1"
    local Size=$(eval echo "\${#${StackVarName}[@]}")
    if (( $Size > 0 )) ; then
        local Last=$(( $Size - 1 ))
        local Top=$(eval echo "\${${StackVarName}[$Last]}")
        echo $Top
    fi
    return 0
}
