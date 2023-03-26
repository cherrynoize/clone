# Clone backup utility

I've always been kinda scared when I had to do a backup. Despite
**rsync** being sort of understanding with my mistakes, there's
something that feels *off* about putting my whole life in the
hands of a single rsync command. But it's not so much rsync, as
much as my ability to store files in pre-arranged sorted locations.

(That trailing slash thing doesn't help though.)

Note that CLI is not the offender here. In fact here I come to you
with **Clone**: *my own* CLI backup utility. It is fast, it is
simple: it's just rsync -- except less scary.

While rsync's versatility makes it by far one of the most
powerful tools for all your remote (and local) file-copying
needs, this little bash script aims at reducing your mind's
overhead by turning manual execution of the whole dull backup
process into a pre-arranged mindless background job which you
hopefully never have to worry about ever again (if you don't want
to).

### Also, some added bonuses


Say stuff about backup and sync modes

## Usage

    clone [mode] [options] [-s sources | -f source_file] [destination]

To view the full usage message type:

    clone -h

## Syntax

Follows GNU cp convention (meaning no BSD trailing slash
extravaganzas).

### Path addressing use cases

"SRC" will be copied as "DEST/SRC"
"SRC/" will be also copied as "DEST/SRC"
The contents of "SRC/." will be copied inside "DEST/."
