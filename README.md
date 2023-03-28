# Clone backup utility

A more easily accessible backup tool with focus on consistency
and automation. 

#### Fast, simple, just *rsync* -- except less scary.

## Why rsync-2?

You may feel like you have no need for this application,
especially if you already mastered a certain degree of confidence
using rsync daily. And that is by all means correct, if you're
comfortable running rsync commands and using it to automate tasks
you can close this tab now. If you, on the other hand, wanted a
simpler and more effective way of configuring backup tasks and
automated syncs using separate job files to define each task and
verifying they are carried out as expected after execution, you
may want to look into this.

While rsync's versatility makes it by far one of the most
powerful file-copying tools out there, this humble bash script
aims at reducing your mind's overhead by turning manual execution
of the whole dull backup process into a pre-arranged mindless
background job which you hopefully never have to worry about
ever again (unless you want to).

## Usage

    clone [mode] [options] [-s sources | -f source_file] [destination]

To view the full usage message type:

    clone -h

## Syntax

Follows GNU cp convention (meaning no BSD trailing slash
extravaganzas).

### Use cases

    clone -s /path/to/src /path/to/dest

The contents of `src` will be copied into `/path/to/dest/src`.

    clone -s /path/to/src/ /path/to/dest

The contents of `src` will also be copied into `/path/to/dest/src`.

    clone -s /path/to/src/. /path/to/dest

The contents of `src` will be copied into `/path/to/dest`.
