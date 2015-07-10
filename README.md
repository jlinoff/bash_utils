# bash_utils
Collection of bash functions for handling low level functions like messages, command monitoring and assertions that use introspection to provide source file names and line numbers. The source code is useful for learning more about bash programming.

## Commands

| Command                     | Description                                 | Example |
| --------------------------- | ------------------------------------------- | ------- |
| utilsArrayContains          | Is element in array.                        | A=(1 2 3); if utilsArrayContains A 3 ; then echo "found" ; else echo "not found" ; fi |
| utilsAssert                 | Do an assertion test.                       | x=23; utilsAssert "(( $x == 23 ))" |
| utilsConvertSecondsToHHMMSS | Convert total sectonds to HH:MM:SS          | x=12345; echo $(utilsConvertSecondsToHHMMSS $x) | 
| utilsDebug                  | Prints a debug message.                     | utilsDebug "Debug message."        |
| utilsErr                    | Prints an error message and exits.          | utilsErr "Error message."          |
| utilsErrNoExit              | Prints an error message but does not exit.  | utilsErrNoExit "Error message."    |
| utilsExec                   | Execute a command, exit on error.           | utilsExec ls -l                    |
| utilsExecNoExit             | Execute a command, do not exit on error.    | utilsExecNoExit e2fsck -p -f /dev/mapper/loop0p1; if (( $? > 1 )) ; then utilsErr "e2fsck failed!"  |
| utilsInfo                   | Prints an information message.              | utilsInfo "Informational message." |
| utilsMax                    | Return the maximum value from the args.     | Max=$(utilsMax 1 2 3 4) # 4        |
| utilsMin                    | Return the minimum value from the args.     | Min=$(utilsMin 1 2 3 4) # 1        |
| utilsStackPush              | Push onto a stack.                          | MyStack=(); utilsStackPush MyStack 1 2 3 |
| utilsStackPop               | Pop off of a stack into a variable.         | Top=0; utilsStackPop MyStack Top; echo $Top |
| utilsStackTos               | Get the top of stack value.                 | echo $(utilsStackTos MyStack)      |
| utilsMkdirs                 | Make multiple directories.                  | utilsMkdirs /foo/bar /foo/spam     |
| utilsWarn                   | Prints a warning message.                   | utilsWarn "Warning message."       |

## Basic Usage Examples
This shows how to use some of these functions.

```bash
#!/bin/bash

source $(dirname $0)/utils.sh

utilsInfo 'Print a message.'
utilsExec ls -1  # exit if the command fails
utilsExecNoExit ls -1  # don't exit if the command fails

utilsDebug 'first line' 'second line'
utilsDebugEnable=0  # disable all debug messages
utilsDebug 'this will not print'

Files=($(ls -1))
utilsAssert "(( ${#Files[@]} > 3 ))"

if ! utilsArrayContains Files "foo.txt" ; then
  utilsErr "Expected file 'foo.txt' does not exist."
fi

Str=$(utilsConvertSecondsToHHMMSS 12345)
echo $Str    # s/b 34:17:36

A=(1 2 3 4 5 6)
utilsInfo "Min=$(utilsMin ${A[@]})"
utilsInfo "Max=$(utilsMax ${A[@]})"

MyStack=()
utilsStackPush MyStack 1 2 3 4
while (( ${#MyStack[@]} )) ; do
  utilsStackPop MyStack Top
  utilsInfo "Top=$Top"
done
```

utilsExec is especially useful to scripts where you need to check
the resuls of some commands and exit if they fail.

## Customizing Message Display

These are the global variables that control the operation of the
utilities.

| Global Variable      | Default | Description                                    |
| -------------------- | ------- | ---------------------------------------------- |
| utilsDebugEnable     |    1    | enable/disable utilsDebug (DEBUG) messages     |
| utilsErrEnable       |    1    | enable/disable utilsErr (ERROR) messages       |
| utilsErrExitCode     |    1    | default utilsErr exit code                     |
| utilsErrNoExitEnable |    1    | enable/disable utilsErrNoExit (ERROR) messages |
| utilsExecExitOnError |    1    | enable/disable exit on error for utilsExec     |
| utilsExecCmd         |    1    | enable/disable utilsExec cmd reporting         |
| utilsExecPwd         |    0    | enable/disable utilsExec pwd reporting         |
| utilsExecTime        |    0    | enable/disable utilsExec cmd timing            |
| utilsExecStatus      |    0    | enable/disable utilsExec cmd status report     |
| utilsInfoEnable      |    1    | enable/disable utilsInfo (INFO) messages       |
| utilsMsgEnable       |    1    | enable/disable all messages                    |
| utilsWarnEnable      |    1    | enable/disable utilsWarn (WARNING) messages    |

Key 0=disabled, 1=enabled

## Customizing Message Format
The message format can be defined by setting utilsMsgPrefixFormat
using the available field types. The field types available are:

| Field     | Description                               |
| --------- | ----------------------------------------- |
| %date     | current date: %Y-%m-%d                    |
| %datetime | timestamp: %Y-%m-%d %H:%M:%S              |
| %file     | the caller file name                      |
| %filebase | the file base name                        |
| %func     | the caller function name                  |
| %line     | the caller line number                    |
| %time     | current time: %H:%M:%S                    |
| %type     | message type: INFO, ERROR, WARNING, DEBUG |

The default setting is:
```bash
utilsMsgPrefixFormat='%date %time %type %filebase %line '
```

Here are some examples of different settings.

```bash
#!/bin/bash
# This file name is test123.sh
source ~/etc/utils.sh

# Default format specified explicitly.
utilsMsgPrefixFormat='%date %time %type %filebase %line '
utilsInfo "test message"
# 2015-07-09 09:52:55.478262680 INFO test123.sh 628 test message

# Useful format for a single script (remove the file name).
utilsMsgPrefixFormat='%date %time %type %line '
utilsInfo "test message"
# 2015-07-09 09:52:55.478262680 INFO 628 test message

# Useful format for scrips that source all sorts of different things.
utilsMsgPrefixFormat='%date %time %type %file %line '
utilsInfo "test message"
# 2015-07-09 09:52:55.478262680 INFO /home/jlinoff/work/test/test123.sh 628 test message

# Another format.
utilsMsgPrefixFormat='[%type] %date : '
utilsInfo "test message"
# [INFO] 2015-07-09 : test message
```
