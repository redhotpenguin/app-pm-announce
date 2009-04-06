package App::PM::Announce::App;

use warnings;
use strict;

use Getopt::Chain;
use App::PM::Announce;
use App::PM::Announce::Util;
use DateTime;
use Text::Table;
use Data::Dump qw/dd pp dump/;

my $app;
my @app;
sub app {
    return $app ||= App::PM::Announce->new(@app);
}

sub run {
    Getopt::Chain->process(
        options => [qw/ verbose|v dry-run|n /],
        run => sub {
            my ($context, @arguments) = @_;
            push @app, qw/debug 1 verbose 1/ if $context->option( 'verbose' );
            push @app, qw/dry_run 1/ if $context->option( 'dry-run' );
            return if @arguments;
            app;
            print <<_END_;

The only thing you can do right now:

    $0 test

Which will submit an announcement to:

    robert...krimen\@gmail.com / test8378 \@ http://www.meetup.com/The-San-Francisco-Beta-Tester-Meetup-Group/calendar/?action=new
    robertkrimen+alice8378\@gmail.com / test8378 \@ http://www.linkedin.com/groupAnswers?start=&gid=1873425
    alice8378 / test8378 \@ http://72.14.179.195/cgi-bin/greymatter/gm.cgi

_END_
        },
        commands => {
            config => sub {
                my ($context, @arguments) = @_;
                my $config = app->config;
                print "\n";
                print "Using config file: ", app->config_file, "\n";
                print "\n";
                print pp $config;
                print "\n\n";
                print "Configured to announce to: ", join ", ", grep { app->config->{feed}->{$_} } qw/meetup linkedin greymatter/;
                print "\n";
#                print "$_ is ", ! app->config->{feed}->{$_} ? "NOT " : "", "configured\n" for qw/meetup linkedin greymatter/;
                print "\n";
            },
            test => sub {
                my ($context, @arguments) = @_;
                $app = App::PM::Announce->new(config_default => {
                    feed => {
                        meetup => {qw{
                            username robert...krimen@gmail.com
                            password test8378
                            uri http://www.meetup.com/The-San-Francisco-Beta-Tester-Meetup-Group/calendar/?action=new
                        }},
                        linkedin => {qw{
                            username robertkrimen+alice8378@gmail.com
                            password test8378
                            uri http://www.linkedin.com/groupAnswers?start=&gid=1873425
                        }},
                        greymatter => {qw{
                            username alice8378
                            password test8378
                            uri http://72.14.179.195/cgi-bin/greymatter/gm.cgi
                        }},
                    },
                });

                my $key = int rand $$;
                my $description = join ' ', @arguments;
                $description ||= 'Default description';
                app->announce(
                    title => "$description ($key)",
                    description => "$description ($key)",
                    venue => 920502,
                    datetime => DateTime->now->add(days => 10),
                );
            },
            template => sub {
                my ($context, @arguments) = @_;
                print STDOUT app->template;
            },
            announce => sub {
                my ($context, @arguments) = @_;
                my ($event, $report) = app->announce( \*STDIN );
                if ($event) {
                    print "\n";
                    print join "\n", @$report, '', '' if @$report;
                    print "\"$event->{title}\" has been announced on: ", join( ', ', map { $event->{"did_$_"} ? $_ : () } qw/meetup linkedin greymatter/ ), "\n";
                    print "The Meetup link is $event->{meetup_link}", "\n" if $event->{meetup_link};
                    print "\n";
                }
            },
            history => sub {
                my ($context, @arguments) = @_;
                my $query = shift @arguments;
                if ($query) {
                    my $event = app->history->find( $query );
                    my $data = $event->{data};
                    {
                        no warnings 'uninitialized';
                        print "\n";
                        print <<_END_;
"$data->{title}"
$event->{uuid}
$data->{meetup_link}
_END_
                        print "Made ", App::PM::Announce::Util->age( $event->{insert_datetime} ) . ' ago', " (", $event->{insert_datetime}, ")\n";
                        print "Announced on ", join( ', ', map { $data->{"did_$_"} ? $_ : () } qw/meetup linkedin greymatter/ ), "\n";
                        print "\n";

                    }
                }
                else {
                    my $verbose = $context->option( 'verbose' );
                    my @all = app->history->all;
                    my @table = map {
                        my $data = $_->{data};
                        my $did;
                        $did += $data->{"did_$_"} ? 1 : 0 for qw/meetup linkedin greymatter/;
                        [
                            $verbose ? $_->{uuid} : substr($_->{uuid}, 0, 8),
                            $data->{title},
                            $verbose ? $_->{insert_datetime} : App::PM::Announce::Util->age( $_->{insert_datetime} ) . ' ago',
                            "$did/3"
                        ];
                    } app->history->all;
                    my $table = Text::Table->new( 'uuid', \' | ', 'title', \' | ', 'age', \' | ', 'did' )->load( @table );
                    print
                        "\n",
                        $table->rule( '-', '+' ),
                        $table->body,
                        $table->rule( '-', '+' ),
                        "\n",
                    ;
                }
            },
        },
    );
}

1;
