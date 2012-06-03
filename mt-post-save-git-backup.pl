#!/usr/bin/perl -w

use strict;
use vars qw($VERSION);

$VERSION = "0.900";

use MT;
use MT::Plugin;

my $plugin = MT::Plugin->new({
    name            => "PostSaveGitBackup",
    author_name     => 'Darren Chamberlain <dlc@sevenroot.org>',
    description     => "Save a backup copy of each template, module, and entry after saving it to the database.",
    version         => $VERSION,
    settings        => MT::PluginSettings->new([
        ['repo_directory', { Default => '' }],
    ]),
    config_template => \&template,
    doc_link        => "https://github.com/dlc/mt-post-save-git-backup/wiki",
});

MT->add_plugin($plugin);

sub template {
    return <<T;
<div class="setting">
    <div class="label">
        <label for="repo_directory">Directory to local git checkout:</label>
    </div>
    <div class="field">
        <input type="text" name="repo_directory" value="<TMPL_VAR NAME=REPO_DIRECTORY ESCAPE=HTML" />
        <p>Must be an existing checkout.</p>
    </div>
</div>
T
}
