# Clone backup automation utility

An easily accessible backup automation tool with focus on consistency
and automation. 

#### Fast, simple, just *rsync*, except less scary.

## Disclaimer

Clone is alpha at best. I've been extensively testing it on my
machine, but still:
- run jobs in verbose mode first and check found maps carefully to
see if they were properly identified;
- always execute using dry-run option first;
- be wary of the recovery option.

This still needs more testing before it can be called complete.

Please open an issue or PR if you find any bug or other nuance in the
program.

## A quick word

If you're comfortable running rsync commands to automate tasks
you probably don't *need* this. But if you wanted a
simpler and more effective way of handling backups and
automated synchronization using separate config files for each task,
implementing auto-tar compression (and therefore data encryption),
structured script execution, incremental backups and easy setup
recovery, then you may want to look into this.

While rsync's versatility makes it one of the most
powerful file-copying tools out there, this humble bash script
aims at reducing your mind's overhead by turning manual execution
of the whole dull backup process into a pre-arranged mindless
background job which you hopefully never have to worry about
ever again.

## Usage

For an easy quickstart just run:

    clone JOB_NAME

Where `JOB_NAME` is the name of your job file.

This illustrates the whole idea behind Clone. Configuring jobs with
all the desired options and commands so you can later just call them
by their name, not worrying about re-defining options each time
(which can be tedious if it's the same job over and over, but even
worse if the command is always changing.

To view the full usage message type:

    clone --help

## Syntax

Follows GNU cp convention (meaning no BSD trailing slash
extravaganza).

### Meaning

    clone -s /path/to/src -d /path/to/dest

The contents of `src` will be copied into `/path/to/dest/src`.

    clone -s /path/to/src/ -d /path/to/dest

The contents of `src` will also be copied into `/path/to/dest/src`.

    clone -s /path/to/src/. -d /path/to/dest

The contents of `src` will be copied into `/path/to/dest`.

## Configuration

Clone can be configured in the default `config.sh` file
or in any job file to be run.

Configuration specified in currently running jobs is local to the
active job only and overrides the main config's.

In config files you can specify additional option parameters, as
well as custom sync maps, commands to be run after job execution,
etc.

Please refer to the example files provided in the repo for specific
syntax and use-cases. You can use these as a starter configuration
and expand upon
them. An in-depth explanation should be overkill if you just stick
to editing the given
values and preserve the basic structure. Key concepts are still
always addressed in comments.

### In-file scripting

The config and job files are all sourced from a bash shell, so any
bash command is technically available. If you want to use local
variables that are not used to communicate directly with clone, you
may want to name the variables starting with an underscore (*_*), to
avoid unknowingly interfering with some program runtime variable.

For instance if you need to use the value multiple times:

    var="/path/to/dir"

You may want to include it like so:

    # here _var is only needed locally (in the same file)
    _var="/path/to/dir"

    # sync_map is a clone-specific variable (-g means global)
    declare -gA sync_map=(
      ["/foo"]="${_var}/foo"
      ["/bar"]="${_var}/bar"
    )

## System cloning

If you want to automate system reproduction a good rule of thumb
is to back up what you know you want to back up, and leave the rest.

Sometimes it's not so easy to keep track of what you want to back
up though. You should update your job file whenever a new location
needs to be synchronized, so that it's done automatically on the next
run.

You can find in the example jobs a useful [sync map of user data
files](jobs/sync.sh) that can be easily translated onto a new system to
replicate the current setup (obviously needs customization, but it's
a starting point). If using rsync you should make sure the backup
partition is formatted accordingly to source so permissions are not
lost, or you can compensate with the aid of third-party applications
(e.g: etckeeper for `/etc` files).

However, creating an archive with tar might be a more suitable option.

Also consider maintaining a list of installed packages in one of the
backed up locations so you can easily reinstall them with your
package manager.

This is an example hook for `pacman` that does just that:

    [Trigger]
    Operation = Install
    Operation = Remove
    Type = Package
    Target = *

    [Action]
    When = PostTransaction
    Exec = /bin/sh -c 'pacman -Qqen > /etc/pacman.d/pkglist; pacman -Qqem > /etc/pacman.d/pkglist_aur'

`pkglist` (as well as `pkglist_aur`) is updated after every package
install or removal. This way if we backup the `/etc` directory, we
inherently have a way of reproducing all binaries, libraries, etc. that
were previously installed using our package manager.

Using the `post-exec` functionality of Clone, we can add something
like:

    # --needed is for idempotency
    pacman -S --needed - < /etc/pacman.d/pkglist; yay -S --needed - < /etc/pacman.d/pkglist_aur

To automatically restore all packages after backup recovery.

This is better than brutally cloning the entire disk or partition
since we let the package manager handle the new system's hardware
and specifications and we also keep our backups much more concise,
meaning reduced write times and energy consumption, decreased risk
of failure and longer hardware life expectancy (good for you, good
for your hardware.) Also, storage is expensive.

## Error codes

    0 OK
    1 command external (e.g: command syntax/arg format)
    2 command internal (e.g: bad configuration)
    3 file (e.g: file not found)
    4 path (e.g: dir not found)

## Contribute

This application is still in *alpha*. So if you want to
contribute, you can just run Clone and submit any bug or unwanted
behaviour either as an issue or as a PR. All feedback and
ideas for improvement are more than welcome.

Also you can check the [TODO](#todo) list in case you feel like
contributing more deeply.

## TODO

- Add timer that tells you total expired time after job execution
- Remove oldest entries after settable amount of incremental backups (`e.g: $max_snapshots`) is reached
- Make log files sub dir specific to each user (i.e: `/var/log/clone/$USER`) - then ensure owner of dir and log files is user
- I did try my best to keep the code tidy but I clearly didn't suceed so if you can refactor some code to improve readability I will gladly accept the PR

## Contacts

Please feel free to
[contact me](https://cherrynoize.github.io/#/contacts) about any
feedback or feature request. Where possible, consider opening a
public issue. 

## Donations

If you wanted to show your support (or just buy me a pizza)
[here](https://cherrynoize.github.io/#/contribute) are some options.

This program is in early development so just running it and
reporting on any issue means a lot already.

### Thank you for using clone.sh.
