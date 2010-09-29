package App::PM::Announce::Feed::linkedin;

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
    $uri = "http://www.linkedin.com/groupAnswers?start=&gid=$uri" if $uri =~ m/^\d+$/;

    $self->get( "https://www.linkedin.com/secure/login" );

    $self->logger->debug( "Login as $username / $password" );

     $self->agent->form_with_fields('session_login','session_key',
         'session_password', 'session_login', 'csrfToken', 'session_rikey');

    $self->submit_form(
        fields => {
            session_key => $username,
            session_password => $password,
        },
        button => 'session_login',
    );

    die "Wasn't logged in" unless $self->content =~ m/If you are not automatically redirected/;

    $self->get( $uri );

    die "Not able to start a discussion via $uri" unless $self->content =~ m/Start a Discussion/;

    $self->submit_form(
        fields => {
            question => $self->format( \%event => 'title' ),
            questionDetail => $self->format( \%event => 'description' ),
        },
        form_number => 2,
        button => 'createQuestion',
    );

    die "Not sure if discussion was posted" unless $self->content =~ m/Your discussion has been posted successfully/;

    $self->logger->debug( "Submitted to linkedin at $uri" );

    return 1;
}

1;
