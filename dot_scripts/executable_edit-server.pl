#!/usr/bin/perl
# A simple web server that just listens for textarea filter requests
# and runs an editor to manipulate the text.  Is intended to be
# used with the TextAid extention for Chrome.
#
# NOTE:  If you use this on a shared system, you should configure TextAid
# with a username & password and make sure that the saved authorization
# config file stays secret!

use strict;
use warnings;
use threads;
use Socket;
use IO::Select;
use File::Temp;
use Getopt::Long;

# If you don't want to require authentication, set $REQUIRE_AUTH to 0.
# When it is set to 1, the first authenticated request that is received
# will be saved to the $SAVE_AUTH_FILE file.  All subsequent requests
# are compared to that value.  To change your password, just remove the
# file and make a new edit-server request using the new auth info.
our $REQUIRE_AUTH = 0;
our $SAVE_AUTH_FILE = "$ENV{HOME}/.edit-server-auth";

# Only accept requests from something that claims to be a chrome-extension.
# Set this to 0 if you want other things to be able to use this script.
our $REQUIRE_CHROME_EXTENSION = 1;

# Configures the port we listen on and if we allow only localhost requests.
our $PORT = 8888;
our $LOCALHOST_ONLY = 1;

# Configure the program that you want to run to handle the requests.
# This editor invocation must NOT return control to this script until
# you are done editing.
# our $EDITOR_CMD = '/usr/bin/gvim -f "%s"';
our $EDITOR_CMD = 'roxterm --separate -T "TextAid-nvim" -e zsh -c "source ~/.zshrc ;wmctrl -a TextAid; nvim \"%s\""';
#our $EDITOR_CMD = '/usr/bin/emacsclient -c "%s"';

# The settings to configure the temp dir and how soon old files are removed.
# If TMPTEMPLATE contains the string -URL64-, then up to 64 chars of the munged
# URL for the textarea's page will be included in the tmp file's filename.
our $TMPDIR = '/tmp';
our $TMPTEMPLATE = 'edit-server-URL64-XXXXXX';
our $TMPSUFFIX = '.txt';
our $CLEAN_AFTER_HOURS = 4;

&Getopt::Long::Configure('bundling');
GetOptions(
    'verbose|v+' => \( my $verbosity = 0 ),
    'help|h' => \( my $help_opt ),
) or usage();
usage() if $help_opt;

umask 0077; # Disables all "group" and "other" perms when saving files.
$|  = 1;

local *S;
socket(S, PF_INET, SOCK_STREAM , getprotobyname('tcp')) or die "couldn't open socket: $!\n";
setsockopt(S, SOL_SOCKET, SO_REUSEADDR, 1);
if ($LOCALHOST_ONLY) {
    bind(S, sockaddr_in($PORT, INADDR_LOOPBACK));
} else {
    bind(S, sockaddr_in($PORT, INADDR_ANY));
}
listen(S, 5) or die "listen failed: $!\n";

my $sel = IO::Select->new();
$sel->add(*S);

while (1) {
    my @con = $sel->can_read();
    foreach my $con (@con) {
	my $fh;
	my $remote = accept($fh, $con);
	my($port, $iaddr) = sockaddr_in($remote);
	my $addr = inet_ntoa($iaddr);

	my $t = threads->create(\&do_edit, $fh);
	$t->detach();
    }
}

exit;

# Read the text from the content body, edit it, and write it back as our output.
sub do_edit
{
    my($fh) = @_;
    binmode $fh;

    local $_ = <$fh>;
    my($method, $path, $ver) = /^(GET|HEAD|POST)\s+(.*?)\s+(HTTP\S+)/;
    print "Path: $path\n" if $verbosity >= 1;
    unless (defined $ver) {
	http_header($fh, 500, 'Invalid request.');
	close $fh;
	return;
    }
    if ($method ne 'POST') {
	http_header($fh, 200, 'OK', 'Server is up and running.  To use it, issue a POST request with the file to edit as the content body.');
	close $fh;
	return;
    }

    my %header;

    while (<$fh>) {
	s/\r?\n$//;
	last if $_ eq '';

	my($name, $value) = /^(.*?): +(.*)/;
	$header{lc($name)} = $value;
	print "Header: \L$name\E = $value\n" if $verbosity >= 2;
    }
    print "-------------------------------------------------------------------\n" if $verbosity >= 2;

    if ($REQUIRE_AUTH) {
	my $authorized;
	my $auth = $header{authorization}; # e.g. "Basic 01234567890ABCDEF=="
	if (defined $auth) {
	    my $line;
	    if (open AUTH, '<', $SAVE_AUTH_FILE) {
		chomp($line = <AUTH>);
		close AUTH;
	    } elsif ($!{ENOENT} && open AUTH, '>', $SAVE_AUTH_FILE) {
		# The first request w/o an auth file saves the auth info.
		print AUTH $auth, "\n";
		close AUTH;
		$line = $auth;
	    } else {
		http_header($fh, 501, 'Internal failure -- auth-file failed.');
		close $fh;
		return;
	    }
	    if ($line eq $auth) {
		$authorized = 1;
	    }
	}
	unless ($authorized) {
	    http_header($fh, 401, 'Unauthorized!');
	    close $fh;
	    return;
	}
    }

    if ($REQUIRE_CHROME_EXTENSION) {
	my $origin = $header{origin};
	unless (defined $origin && $origin =~ /^chrome-extension:/) {
	    http_header($fh, 401, 'Unauthorized.');
	    close $fh;
	    return;
	}
    }

    my $len = $header{'content-length'};
    unless (defined $len && $len =~ /^\d+$/) {
	http_header($fh, 500, 'Invalid request -- no content-length.');
	close $fh;
	return;
    }

    my $got = read($fh, $_, $len);
    if ($got != $len) {
	http_header($fh, 500, 'Invalid request -- wrong content-length.');
	close $fh;
	return;
    }

    my($query) = $path =~ /\?(.+)/;
    (my $template_fn = $TMPTEMPLATE) =~ s/-URL(\d+)-/ '-' . url_filename($query, $1) . '-' /e;

    my $tmp = new File::Temp(
	TEMPLATE => $template_fn,
	DIR => $TMPDIR,
	SUFFIX => $TMPSUFFIX,
	UNLINK => 0,
    );
    my $name = $tmp->filename;

    print $tmp $_;
    close $tmp;

    my $cmd = sprintf($EDITOR_CMD, $name);
    system $cmd;

    unless (open FILE, '<', $name) {
	http_header($fh, 500, "Unable to re-open $name: $!");
	close $fh;
	return;
    }

    http_header($fh, 200, 'OK', '');
    print $fh <FILE>;

    close FILE;
    close $fh;

    # Clean-up old tmp files that have been around for a few hours.
    if (opendir(DP, $TMPDIR)) {
	(my $match = quotemeta($TMPTEMPLATE . $TMPSUFFIX)) =~ s/(.*[^X])(X+)/ $1 . ('\w' x length($2)) /e;
	$match =~ s/\\-URL\d+\\-/-.*-/;
	print "Match: $match\n" if $verbosity >= 3;
	foreach my $fn (grep /^$match$/o, readdir DP) {
	    $fn = "$TMPDIR/$fn";
	    print "Fn: $fn\n" if $verbosity >= 3;
	    my $age = -M $fn;
	    if ($age > $CLEAN_AFTER_HOURS/24) {
		unlink $fn;
	    } else {
		print "Age: $age\n" if $verbosity >= 3;
	    }
	}
	closedir DP;
    }
}

sub http_header
{
    my $fh = shift;
    my $status = shift;
    my $status_txt = shift;
    @_ = $status_txt unless @_;
    print $fh "HTTP/1.0 $status $status_txt\r\n",
	      "Server: edit-server\r\n",
	      "Content-Type: text/plain\r\n",
	      "\r\n", @_;
}

sub url_filename
{
    my($query, $max_chars) = @_;
    print "Query: $query\n" if $verbosity >= 4;

    if (defined $query) {
	foreach my $var_val (split /&/, $query) {
	    my($var, $val) = split /=/, $var_val, 2;
	    if ($var eq 'url') {
		print "Before: $val\n" if $verbosity >= 4;
		$val =~ s/\%([0-9a-fA-F]{2})/ chr hex $1 /eg;
		$val =~ s{^https?://}{};
		$val =~ s/[^-\w.]+/_/g;
		$val =~ s/^(.{1,$max_chars}).*/$1/;
		print "After: $val\n" if $verbosity >= 4;
		return $val;
	    }
	}
    }

    return 'unknown-url';
}

sub usage
{
    die <<EOT;
Usage: edit-server [OPTIONS]

Options:
 -v, --verbose     Increase debug verbosity (repeatable)
 -h, --help        Output this help message
EOT
}
