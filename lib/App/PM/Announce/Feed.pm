package App::PM::Announce::Feed;

use warnings;
use strict;

use Moose;

use WWW::Mechanize;
use HTTP::Request::Common qw/GET POST/;
use HTML::TreeBuilder;

has username => qw/is ro isa Str required 1/;
has password => qw/is ro isa Str required 1/;

has agent => qw/is ro lazy_build 1/, handles => [qw/ submit_form /];
sub _build_agent {
    return WWW::Mechanize->new;
}

sub get {
    my $self = shift;
    $self->agent->request( GET @_ );
}

sub post {
    my $self = shift;
    $self->agent->request( POST @_ );
}

sub content {
    my $self = shift;
    return $self->agent->content;
}

sub tree {
    my $self = shift;
    return HTML::TreeBuilder->new_from_content( $self->content );
}

sub format {
    my $self = shift;
    my $event = shift;
    my $key = shift;
    
    my $value = $event->{$key};

    if ($key eq 'description') {
        $value = join "\n\n", @$value if ref $value eq 'ARRAY';
    }

    return $value;
}

1;
