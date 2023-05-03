# Clone backup automation utility

An easily accessible backup automation tool with focus on consistency
and automation. 

#### Fast, simple, just *rsync*--except less scary.

## Disclaimer

clone is alpha at best. I've been extensively testing it on my
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

    clone [options] [-f config_file] [-s sources -d destination | jobs] 

To view the full usage message type:

    clone -h|--help

## Syntax

Follows GNU cp convention (meaning no BSD trailing slash
extravaganzas).

### Meaning

    clone -s /path/to/src -d /path/to/dest

The contents of `src` will be copied into `/path/to/dest/src`.

    clone -s /path/to/src/ -d /path/to/dest

The contents of `src` will also be copied into `/path/to/dest/src`.

    clone -s /path/to/src/. -d /path/to/dest

The contents of `src` will be copied into `/path/to/dest`.

## Configuration

clone can be configured in the default config file (defined at the
top of the clone script) or in any job file to be run.

Configurations specified in currently running jobs is local to the
active job only and overrides main config file's parameters.

In config files you can specify additional option parameters, as
well as custom sync maps, commands to be run after job execution,
etc.

Please refer to the example files provided in the repo for specific
syntax. You can use these as a starter configuration and expand upon
them. An in-depth explanation should be overkill if you just edit the
values and preserve the basic structure. Key concepts are still
addressed in comments.

## System cloning

If you want to automate system reproduction a good rule of thumb
is to back up what you know you want to back up, and leave the rest.

Sometimes it's not so easy to keep track of what you edited and so
on. You should update your job file in time when a new location
needs to be synchronized, so that it's done automatically the next
time it is run.

You can find in the example jobs a [useful sync map of user-relevant
files](jobs/sync.sh) that can be easily translated to a new system to
replicate the current setup (obviously needs customization, but it's
a starting point). You should make sure the backup partition
is formatted accordingly to source so permissions are not lost,
or you can compensate with the aid of third-party applications (e.g:
etckeeper for /etc files).

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
also have a way of reproducing all binaries, libraries, etc. that
were previously installed using our package manager.

Using the `post-exec` functionality of clone, we can add something
like:

    # --needed is for idempotency
    pacman -S --needed - < /etc/pacman.d/pkglist
    yay -S --needed - < /etc/pacman.d/pkglist_aur

To automatically restore all packages after backup recovery.

This is better than brutally cloning the entire disk or partition
since we let the package manager handle the new system's hardware
and specifications and we also keep our backups much more concise,
meaning reduced write times and energy consumption, decreased risk
of failure and longer hardware life expectancy (good for you, good
for your hardware.) Also, storage is expensive.

## Error codes

- 0 OK
- 1 command external (e.g: command syntax/arg format)
- 2 command internal (e.g: bad configuration)
- 3 file (e.g: file not found)
- 4 path (e.g: dir not found)

## Contribute

This application is still in **alpha**. So if you want to
contribute, just run clone and submit any bug or unwanted
behaviour either as an issue or as a PR. All feedback and
potential improvements are well accepted.

## Contacts

> [u/cherrynoize](https://www.reddit.com/user/cherrynoize)
>
> [cherrynoize@duck.com](mailto:cherrynoize@duck.com)

Please feel free to contact me about any feedback or feature
request. Or where possible, please do open a public issue. 

## Donations

If you wanted to show your support or just buy me a pizza:

    ETH   0x5938C4DA9002F1b3a54fC63aa9E4FB4892DC5aA8

    SOL   G77bErQLYatQgMEXHYUqNCxFdUgKuBd8xsAuHjeqvavv

    BNB   0x0E0eAd7414cFF412f89BcD8a1a2043518fE58f82

    LUNC  terra1n5sm6twsc26kjyxz7f6t53c9pdaz7eu6zlsdcy

### Thank you for using clone.sh.
