This is a very simple rsync backup script, very much inspired by rsnapshot,
but with very few dependencies (just a bash and rsync) and backups are pushed
to a server rather than pulled in.

Incremental snapshots are rotated in hourly, daily, weekly and monthly intervals.

For usage and configuration details, please refer to the [documentation](doc/README.md).
