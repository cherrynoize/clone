# Clone backup utility

A more easily accessible backup tool with focus on consistency
and automation. 

#### Fast, simple, just *rsync* -- except less scary.

## rsync *2*?

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

    clone [options] [-f config_file] [-s sources -d destination | jobs] 

To view the full usage message type:

    clone -h|--help

## Syntax

Follows GNU cp convention (meaning no BSD trailing slash
extravaganzas).

### Use cases

    clone -s /path/to/src -d /path/to/dest

The contents of `src` will be copied into `/path/to/dest/src`.

    clone -s /path/to/src/ -d /path/to/dest

The contents of `src` will also be copied into `/path/to/dest/src`.

    clone -s /path/to/src/. -d /path/to/dest

The contents of `src` will be copied into `/path/to/dest`.

## Contribute

This application is still in **alpha**. So if you want to
contribute, just run the program and submit any bug or unwanted
behaviour either as an issue or as a PR. All feedback and
potential improvements are well accepted.

## Contacts

> [u/cherrynoize](https://www.reddit.com/user/cherrynoize)
>
> [0xo1m0x5w@mozmail.com](mailto:0xo1m0x5w@mozmail.com)

Please feel free to contact me about any feedback or feature
request. Or where possible, please do open a public issue. 

## Donations

If you wanted to show your support or just buy me a pizza:

    ETH   0x5938C4DA9002F1b3a54fC63aa9E4FB4892DC5aA8

    SOL   G77bErQLYatQgMEXHYUqNCxFdUgKuBd8xsAuHjeqvavv

    BNB   0x0E0eAd7414cFF412f89BcD8a1a2043518fE58f82

    LUNC  terra1n5sm6twsc26kjyxz7f6t53c9pdaz7eu6zlsdcy

### Thank you for using clone.sh.
