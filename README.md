mt-post-save-git-backup
=======================

Movable Type plugin to save a backup copy of each template, module,
and entry after saving it to the database.

To use, create an empty git repo somewhere as the web user:

  # su - www-data
  $ cd /tmp
  $ mkdir backup
  $ cd /tmp/backup
  $ git init

Install the plugin (assumes MTOS-4.38 in a default-ish place):

  $ cd /var/www/htdocs/MTOS-4.38-en/plugins
  $ git clone https://dlc@github.com/dlc/mt-post-save-git-backup.git MTPostSaveGitBackup

Configure the plugin through the MT interface, setting the repo_directory
field to the directory you configured in the first step.

That's it -- There are post-save hooks for templates and entries
that will save your changes in the configured directory, and commit
them. Note that this doesn't do anything else, like push to github
or another host; you'll need to set up a cronjob to do that, or do
it manually, if that's something you need.
