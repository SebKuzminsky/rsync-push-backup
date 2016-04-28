## TOC
In this document you will find:

* [Requirements](#requirements)
* [Installation](#installation)
* [Configuration](#configuration)
    * [The `config` files](#the-config-files)
    * [The `exclude` files](#the-exclude-files)
    * [Automated runs](#automated-runs)
* [Usage](#usage)
* [Results](#results)


## Requirements
Other than comparable solutions, this script has no requirements which are
not met by most Linux distributions out-of-the-box: You will need `rsync` and
`ssh` on both ends, plus Bash on the client (where the script runs). Most Linux
distributions ship that per default, on some you might have to install `ssh`
manually. For the client that would be the package `openssh-client`, the server
would need `openssh-server`, and those packages can be found in the standard
repositories of most distributions.

If the `use_notify` config option is set, then there is an additional
dependency on the notify-send program (part of Gnome, provided by the
libnotify-bin package on Debian).


## Installation
Simply put the `backup` script to `/usr/local/bin` if you want to have it in
the `$PATH` for all users. You can also place it into `~/bin` if only one
user needs it, or to any directory of your choice (if it's not in the `$PATH`,
you'll then have to call it with its full path, e.g. `/opt/scripts/backup`.

Configuration files by default are looked for in `~/.backup` (though you can
define a different place on the command line, see "Usage" below). In the main
config directory there's the global `config` file, and a sub-directory per
"module" (so you can have different sets). In addition to their own `config`
file (which overrides settings made in the global `config`), modules have a
second file named `exclude`:

* `config`: in this file you define the behaviour of the script
* `exclude`: here you define which files and directories should be (not)
  backed up

So basically, your backup directory has a structure like this:

    .backup
    ├── config
    ├── module1
    │   ├── config
    │   └── exclude
    └── module2
        ├── config
        └── exclude


## Configuration
### The `config` files
As already said, this is where you define the behavior: where to backup from
and to, how many backups to keep, and so on. Settings valid for all (or
most/many) of your modules go to the main `config`, module-specific settings
are done in the module specific `config` file (and override global settings).
The following keywords are available:

* `backup_host=backuphost`: where to backup to. This is either the host name
  only (if your logins are identical), or `user@host` to use a different account
  on the backup machine.
* `ssh_id`: The ssh key to use to authenticate with the backup_host. Leave it unset
  (or set it to the empty value) to skip ssh key authentication (or use your
  default identity as setup in your `~/.ssh/config`).
* `remote_path=Backup/$(uname -n)`: path to your backups on the remote machine.
  this can be an absolute path (starting with a `/`) or one relative to the
  user's home directory. In our example, the `$(uname -n)` would automatically
  insert the local host name, so you know where the backups are from.  Each
  module is backed up to its own subdirectory under the remote_path
  directory, independent of all other modules. This subdirectory's name will
  be the same as the module's name.
* `backup_root=$HOME/`: This is on the local host, the directory holding the
  stuff you want to back up. Note that we can define excludes and includes from
  this with the `exclude` file, as described below.
* `hourly_snapshots=6`: how many hourly snapshots to keep (older ones will be removed)
* `daily_snapshots=7`: same for daily snapshots
* `weekly_snapshots=4`: same for weekly snapshots
* `monthly_snapshots=12`: same for monthly snapshots
* `use_notify=yes`: Set the "use_notify" variable to a non-empty value to turn
   on desktop notifications. Leave it unset (or set to an empty value) to disable
   desktop notifications (which you most likely will want to do for e.g. hourly
   backups via cron).  
   rsync-push-backup uses the "notify-send" program to send desktop notifications.
* `max_size=10m`: If set, skip files larger than defined here (in this example,
   10 MiB). In general, this means: Don't tranfer files bigger than this many
   bytes.  
   Default: transfer every file that's not listed in the exclude file, regardless
   of size. Note that files skipped by the size limitation do not get removed
   from the far side, unlike files excluded by the exclude file.  
   Accepts the same kinds of values as rsync's --max-size argument,
   typically a number followed by an optional size multiplier, so for
   example "500" means 500 bytes and "1.5m" means 1.5 megabytes.  See the
   rsync(1) manpage for details.
* `bwlimit=100k`: This  option allows you to specify the maximum transfer rate
   for the data pushed to the backup server.   
   Default: send as fast as possible, with no limiting of bandwidth.  
   Specified in "units per second". The default units are kilobytes (1024
   bytes), but this can be changed with an optional multiplier suffix.
   So for example, "16" means "16 kilobytes/second", "100k" means "100
   kilobytes per second", and "1.5m" means "1.5 megabytes per second".  
   See the rsync(1) manpage for details.


### The `exclude` files
Here you can define exceptions, or "special handlings". `rsync` provides a quite
dynamic configuration here. For full details, please consult the section named
"Include/Exclude Pattern Rules" in the [rsync man page](http://linux.die.net/man/1/rsync)
(locally available via `man rsync`). I will stick to the very basic rules here,
which should be sufficient in most cases.

Each line in this file defines one rule. Empty lines as well as lines starting
with a `#` are ignored. `rsync` matches each file against the rules here, the
first hit decides what it does with it. Use a `+` to have a file/directory
included, a `-` to have it excluded from backups. A trailing slash defines a
directory (with all its contents). Our example definition would backup the
entire `backup_root` – except for the `Downloads/` directory. It further would
exclude all "hidden directories" (those starting with a dot in their name)
except for the three explicitly included. Important note on that: as `rsync`
takes the first match for a file, we first need to place the explicit includes
(those three dot-directories we want to back up), and *after that* exclude all
others:

    + .emacs.d/
    + .backup/
    + .ssh/
    - .*/
    - Downloads/


### Automated runs
For automated runs, you can use a corresponding crontab entry. To not be
"spammed hourly", it is recommended to turn off notifications and "regular
output" – but keep "error output" activated to be made aware if something
goes wrong. This cound be achieved e.g. with the following crontab entry:

    49 * * * * $HOME/bin/backup >/dev/null

As a result, the script would run "silently" as long as no errors occur. If
there are any errors, you'd be notified per mail (as with other cron jobs).

Alternatively, you might decide to have all output logged into a file:

    49 * * * * $HOME/bin/backup > $HOME/.backup/log 2>&1

Here "normal output" is redirected to the `$HOME/.backup/log` file, and
error output redirected to "normal output" – so all goes into that file.
As only a single `>` is used for the file, it will be overwritten on each
run (so you don't need to care for truncating it). Use a double `>>` if
subsequent runs should rather *append* to the log.

Here is what the original developer of the script used:

    @reboot $HOME/bin/backup > $HOME/.backup/log 2>&1
    49 * * * * $HOME/bin/backup > $HOME/.backup/log 2>&1


## Usage
Simply call the script with solely the `-h` parameter to reveal its syntax:

    usage: backup [OPTIONS] [MODULE...]
    
    OPTIONS:
        -c CONFIGDIR   Read configuration from CONFIGDIR instead of
                       the default: $HOME/.backup
        -h             Show this help.
    
    MODULE... names one or more modules to back up.  If no MODULE is named, all
    modules are backed up.


## Results
The result (on the backup server) will look something like this for each module:

<pre>
lrwxrwxrwx  1 miklo miklo   10 2011-12-13 20:11 daily.0 -> ./hourly.6
drwxr-xr-x 18 miklo miklo 4096 2011-12-12 19:49 daily.1
drwxr-xr-x 18 miklo miklo 4096 2011-12-11 20:50 daily.2
drwxr-xr-x 18 miklo miklo 4096 2011-12-10 11:49 daily.3
drwxr-xr-x 18 miklo miklo 4096 2011-12-07 21:49 daily.4
drwxr-xr-x 18 miklo miklo 4096 2011-12-07 20:49 daily.5
drwxr-xr-x 18 miklo miklo 4096 2011-12-06 21:49 daily.6
drwxr-xr-x 18 miklo miklo 4096 2011-12-13 21:49 daily.7
drwxr-xr-x 18 miklo miklo 4096 2011-12-13 21:49 hourly.0
drwxr-xr-x 18 miklo miklo 4096 2011-12-13 21:49 hourly.1
drwxr-xr-x 18 miklo miklo 4096 2011-12-13 20:49 hourly.2
drwxr-xr-x 18 miklo miklo 4096 2011-12-13 20:11 hourly.3
drwxr-xr-x 18 miklo miklo 4096 2011-12-12 23:49 hourly.4
drwxr-xr-x 18 miklo miklo 4096 2011-12-12 22:49 hourly.5
drwxr-xr-x 18 miklo miklo 4096 2011-12-12 21:49 hourly.6
lrwxrwxrwx  1 miklo miklo   10 2011-12-13 21:49 monthly.0 -> ./weekly.4
lrwxrwxrwx  1 miklo miklo    9 2011-12-11 18:49 weekly.0 -> ./daily.7
</pre>
