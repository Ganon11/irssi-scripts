## Put me in ~/.irssi/scripts, and then execute the following in irssi:
##
##       /load perl
##       /script load notifier-growl.pl
##

use lib '/home/user/mstark/local/lib/perl5/site_perl/5.16.0/';
#use strict;
use warnings;
use threads;
use Thread::Queue;
use Irssi;
use vars qw($VERSION %IRSSI);
use HTML::Entities;
use Growl::GNTP;

$VERSION = "0.01";
%IRSSI = (
    name        => 'notifier-growl.pl'
);

# Default settings in Irssi
Irssi::settings_add_str('notifier','growl_host', 'localhost');
Irssi::settings_add_str('notifier','growl_port', 0);
Irssi::settings_add_str('notifier','growl_password',"");
Irssi::settings_add_bool('notifier','notifier_mute',0);

# Fetch settings from Irssi
my $growl_host = Irssi::settings_get_str('growl_host');
my $growl_port = Irssi::settings_get_str('growl_port');
die "need to select a growl port other than 0"if $growl_port eq 0;
my $growl_password = Irssi::settings_get_str('growl_password');

my $message_queue = Thread::Queue->new();

my $sender_thr = threads->create(sub {
  { package Irssi::ServerConnect }
  { package Irssi::ServerSetup }
  { package Irssi::Chatnet }
  { package Irssi::Nick }
  my $growl = Growl::GNTP->new(
    AppName => "Irssi",
    PeerHost => $growl_host,
    PeerPort => $growl_port,
    Password => $growl_password,
    AppIcon => "http://www.43oh.com/wp-content/uploads/2010/11/msp430_ircl_channel_43oh.png",
  );
  while (my $message = $message_queue->dequeue(1)) {
    local $SIG{'__WARN__'} = sub {};
    eval {
      $growl->register([{ Name => "irssi",},]);
      $growl->notify(
                     Event => "irssi",
                     Title => $message,
                    );
    };
  }
});

$sender_thr->detach();

my $notify = sub {
    my ($server, $summary, $message) = @_;

#    print "notify(): '$server' '$summary' '$message'";

    # Encode certain characters using HTML
    my $safemsg = HTML::Entities::encode($message, '<>&"');

    no warnings 'closure';
    $message_queue->enqueue("$summary: $safemsg");
};

my $print_text_notify = sub {
    my ($dest, $text, $stripped) = @_;
    my $server = $dest->{server};
    #print "server: $server, text: '$text', stripped: $stripped";
    return if (!$server || !($dest->{level} & (MSGLEVEL_HILIGHT)));
    my $sender = $stripped;
    $sender =~ s/^\<.([^\>]+)\>.+/$1/ ;
    $stripped =~ s/^\<.[^\>]+\>.// ;
    my $summary = "Hilite in " . $dest->{target};
    &$notify($server, $summary, $stripped);
};

my $message_public_notify = sub {
  my ($server, $msg, $nick, $address, $channel) = @_;
  return if (!$server);
  my $mute = Irssi::settings_get_bool('notifier_mute');
  my $irc_nick = Irssi::settings_get_str('nick');
  #print "mute: $mute, irc_nick: $irc_nick, msg: '$msg'";
  return if ($mute and $msg !~ /$irc_nick/g);
  &$notify($server, "In $channel, $nick said", $msg);
};

my $message_private_notify = sub {
  my ($server, $msg, $nick, $address) = @_;
  return if (!$server);
  &$notify($server, "Private message from ".$nick, $msg);
};

my $cmd_debug = sub {
  #$message_queue->enqueue("Foo", "Bar");
  #print "irc_nick: $irc_nick"
};

#Irssi::signal_add('print text', $print_text_notify);
Irssi::command_bind('growl_dbg', $cmd_debug);
Irssi::signal_add('message private', $message_private_notify);
Irssi::signal_add('message public', $message_public_notify);
