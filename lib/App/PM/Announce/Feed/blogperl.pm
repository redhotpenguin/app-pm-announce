package App::PM::Announce::Feed::blogperl;

use warnings;
use strict;

use Moose;
extends 'App::PM::Announce::Feed';

sub announce {
    my $self = shift;
    my %event = @_;

    my $username = $self->username;
    my $password = $self->password;
    my $uri = $self->uri;

    $self->get( "http://blogs.perl.org/mt/mt.fcgi?__mode=view&_type=entry&blog_id=210" );

    $self->logger->debug( "Login as $username / $password" );

     $self->agent->form_with_fields('username','password',);

    $self->submit_form(
        fields => {
            username => $username,
            password => $password,
        },
    );


    $self->submit_form(
        fields => {
            title => $self->format( \%event => 'title' ),
            text  => $self->format( \%event => 'description' ),
        },
        form_name => 'entry_form',
    );

    die "Not sure if discussion was posted: " unless $self->content =~ m/This entry has been saved/;

    $self->logger->debug( "Submitted to blogperl at $uri" );

    return 1;
}

1;
