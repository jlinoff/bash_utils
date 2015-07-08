# bash_utils
Collection of bash functions for handling low level functions like messages, command monitoring and assertions that use intropsection to provide source file names and line numbers. The source code is useful for learning more about bash programming.

## Commands

| Command                     | Description                                 |
| --------------------------- | ------------------------------------------- |
| utilsArrayContains          | Is element in array.                        |
| utilsAssert                 | Do an assertion test.                       |
| utilsConvertSecondsToHHMMSS | Convert total sectonds to HH:MM:SS          |
| utilsDebug                  | Prints a debug message.                     |
| utilsErr                    | Prints an error message and exits.          |
| utilsErrNoExit              | Prints an error message but does not exit.  |
| utilsExec                   | Execute a command with options for exiting. |
| utilsInfo                   | Prints an information message.              |
| utilsMkdirs                 | Make multiple directories.                  |
| utilsWarn                   | Prints a warning message.                   |

## Usage Examples
This shows how to use some of these functions.

```bash
#!/bin/bash

source $(dirname $0)/utils.sh

utilsInfo 'Print a message.'
utilsExec ls -1  # exit if the command fails

utilsExecExitOnError=0
utilsExec ls -1  # don't exit if the command fails
utilsExecExitOnError=1

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
```
utilsMsgPrefixFormat='%date %time %type %file %line '
```
