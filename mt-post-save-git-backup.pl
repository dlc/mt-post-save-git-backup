#!/usr/bin/perl -w

use strict;
use vars qw($VERSION $ME);

$ME = basename $0;
$VERSION = "0.900";

use Cwd qw(cwd);
use Data::Dumper;
use File::Basename qw(basename);
use File::Path qw(mkpath);
use MT;
use MT::Log;
use MT::Plugin;
use MT::Template;
use MT::Template::Context;
use MT::Trackback;

my $plugin = MT::Plugin->new({
    name                    => "Post-Save Git Backup",
    author_name             => 'Darren Chamberlain <dlc@sevenroot.org>',
    version                 => $VERSION,

    description             => "Save a backup copy of each template, module, and entry after saving it to the database.",

    blog_config_template    => 'blog-config.tmpl',

    settings                => MT::PluginSettings->new([
        ['repo_directory', { Default => '' }],
    ]),

    doc_link                => "https://github.com/dlc/mt-post-save-git-backup/wiki",
});

MT->add_plugin($plugin);

MT::Template->add_callback('post_save', 10, $plugin, sub {
    my ($cb, $obj, $original) = @_;

    my $blog_id = $obj->blog_id;
    if (my $dir = $plugin->get_config_value('repo_directory', "blog:$blog_id")) {
        my $cwd = cwd;

        my $type = "templates/" . $obj->type;
        my $name = $obj->name;

        if (chdir $dir) {
            my $out = "";
            if (! -d "$dir/$type") {
                mkpath("$dir/$type");
                $out .= `git add $type`;
            }

            if (open my $fh, ">$dir/$type/$name") {
                print $fh $obj->text;

                $out .= `git add '$type/$name'`;
                $out .= `git commit -m'Automatic commit' '$type/$name'`;
            }

            if ($out) {
                MT->log({
                    message     => $out,
                    class       => "system",
                    category    => "plugin",
                    level       => MT::Log::INFO(),
                });
            }
        }
        chdir $cwd;
    }
});


MT::Entry->add_callback('post_save', 10, $plugin, sub {
    my ($cb, $obj, $original) = @_;

    my $blog_id = $obj->blog_id;
    if (my $dir = $plugin->get_config_value('repo_directory', "blog:$blog_id")) {
        my $cwd = cwd;

        my $type = "entries";
        my $name = $obj->basename . ".txt";

        if (chdir $dir) {
            my $out = "";
            if (! -d "$dir/$type") {
                mkpath("$dir/$type");
                $out .= `git add $type`;
            }

            if (open my $fh, ">$dir/$type/$name") {
                print $fh format_entry($obj);

                $out .= `git add '$type/$name'`;
                $out .= `git commit -m'Automatic commit' '$type/$name'`;
            }

            if ($out) {
                MT->log({
                    message     => $out,
                    class       => "system",
                    category    => "plugin",
                    level       => MT::Log::INFO(),
                });
            }
        }
        chdir $cwd;
    }
});

# Stolen from MT::ImportExport
sub format_entry {
    my $e = shift;

    my $tmpl = MT::Template->new;
    $tmpl->name('Export Template');
    $tmpl->text(<<'TEXT');
AUTHOR: <$MTEntryAuthor strip_linefeeds="1"$>
TITLE: <$MTEntryTitle strip_linefeeds="1"$>
BASENAME: <$MTEntryBasename$>
STATUS: <$MTEntryStatus strip_linefeeds="1"$>
ALLOW COMMENTS: <$MTEntryFlag flag="allow_comments"$>
CONVERT BREAKS: <$MTEntryFlag flag="convert_breaks"$>
ALLOW PINGS: <$MTEntryFlag flag="allow_pings"$><MTIfNonEmpty tag="MTEntryCategory">
PRIMARY CATEGORY: <$MTEntryCategory$></MTIfNonEmpty><MTEntryCategories>
CATEGORY: <$MTCategoryLabel$></MTEntryCategories>
DATE: <$MTEntryDate format="%m/%d/%Y %I:%M:%S %p"$><MTEntryIfTagged>
TAGS: <MTEntryTags include_private="1" glue=","><$MTTagName quote="1"$></MTEntryTags></MTEntryIfTagged>
-----
BODY:
<$MTEntryBody convert_breaks="0"$>
-----
EXTENDED BODY:
<$MTEntryMore convert_breaks="0"$>
-----
EXCERPT:
<$MTEntryExcerpt no_generate="1" convert_breaks="0"$>
-----
KEYWORDS:
<$MTEntryKeywords$>
-----
<MTComments>
COMMENT:
AUTHOR: <$MTCommentAuthor strip_linefeeds="1"$>
EMAIL: <$MTCommentEmail strip_linefeeds="1"$>
IP: <$MTCommentIP strip_linefeeds="1"$>
URL: <$MTCommentURL strip_linefeeds="1"$>
DATE: <$MTCommentDate format="%m/%d/%Y %I:%M:%S %p"$>
<$MTCommentBody convert_breaks="0"$>
-----
</MTComments>
<MTPings>
PING:
TITLE: <$MTPingTitle strip_linefeeds="1"$>
URL: <$MTPingURL strip_linefeeds="1"$>
IP: <$MTPingIP strip_linefeeds="1"$>
BLOG NAME: <$MTPingBlogName strip_linefeeds="1"$>
DATE: <$MTPingDate format="%m/%d/%Y %I:%M:%S %p"$>
<$MTPingExcerpt$>
-----
</MTPings>
--------
TEXT

    my $ctx = MT::Template::Context->new;
    $ctx->stash('entry',   $e);
    $ctx->stash('blog',    $e->blog);
    $ctx->stash('blog_id', $e->blog_id);
    $tmpl->blog_id($e->blog_id);
    $ctx->{current_timestamp} = $e->created_on;
    my $res = $tmpl->build($ctx);

    return $res;
}
