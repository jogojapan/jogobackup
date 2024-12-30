# jogobackup
Defining a docker image for regular backups to Amazon S3. Optimizes
for cost by combining source-side and destination-side incrementality.

## How it works
You run this as a Docker container, using
[Docker](https://docs.docker.com/) or
[`docker-compose`](https://docs.docker.com/compose/) (or a Docker
management UI like [Portainer](https://www.portainer.io/)). You map
one or more source directories into the container, and specify what
Amazon S3 bucket to back them up, and at what frequency.

It then sets up a cronjob and performs regular backups. Unlike many
other backup docker images you'll find, the backup procedure we use
has some nice characteristics, which in many scenarios will help you
reduce cost:

* Each file in the source directory is backed up separately, rather
  than combining them all into one big tar-ball.
* Only files that have changed since the previous backup are actually
  copied.
* The check for what has changed is done based on the local
  modification timestamp, not by comparing the local timestamp with
  the one recorded on the Amazon S3 side. So if a file has not
  changed, there will be zero cost. (Other backup systems do this by
  always comparing all local timestamps of all files to the timestamps
  stored remotely. So there is always cost at least for retrieving all
  timestamps.)

**Wouldn't a big tar-ball be more efficient?** It can be. The
advantage of using a tar-ball would be that you get one large file,
instead of lots of small ones. Files less than 128KB in size can be
expensive on Amazon S3 because they are not allowed in low-cost
low-frequency storage classes like `DEEP_ARCHIVE`. On the other hand,
if you follow an approach based on tar-balls, you lose
incrementality. For example, running a daily backup then means forming
and copying the entire tar-ball every day, even if only one small file
has changed since the previous backup.

**So, weigh your options:** If you have mostly small files (less than
128KB in size), and the total volume is less than, say, 1GB, then
you'll be better of using a backup approach based on tar-balls. That
is not supported by the tools we provide here. But if you have a large
overall amount of data (e.g., hundreds of GBs), and most of the files
are relatively large (>128KB), then the tools provided here will be
best for you. You can run frequent backups, even hourly, and have
virtually zero cost if your files never change.

## Configuration

1. Prepare an empty directory for **jogobackup** to store its meta
   data. (It'll just use a few bytes of space.) This is optional
   because the system will store the meta data internally in a Docker
   volume if you don't prepare it. But it helps in case you want to
   upgrade to an improved version of `jogobackup` in the future and
   can then easily preserve the meta data.
1. Use the `docker-compose.yml` we provide and the `.env` environment
   variables. Some of the values of these you'll have to update.

## Known Issues
In the log output, you'll find entries such as this:

    2024/12/30 22:00:00 NOTICE: Config file "/root/.config/rclone/rclone.conf" not found - using defaults

This is as expected and no cause for alarm. It's a note by `rclone`
(which is used internally) due to the fact that we control the
`rclone` behavior through environment variables, rather than a config
file.
