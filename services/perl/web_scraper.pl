package WebScraper;

use strict;
use warnings;
use LWP::UserAgent;
use HTML::TreeBuilder;

sub new {
    my ($class) = @_;
    my $self = {
        ua => LWP::UserAgent->new(timeout => 10),
    };
    return bless $self, $class;
}

sub fetch {
    my ($self, $url) = @_;
    my $response = $self->{ua}->get($url);
    
    if ($response->is_success) {
        return $response->decoded_content;
    } else {
        die "Failed to fetch $url: " . $response->status_line;
    }
}

sub parse_html {
    my ($self, $html) = @_;
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($html);
    $tree->eof;
    return $tree;
}

sub extract_links {
    my ($self, $tree) = @_;
    my @links = $tree->look_down(_tag => 'a');
    return map { $_->attr('href') } grep { defined $_->attr('href') } @links;
}

sub extract_text {
    my ($self, $tree, $selector) = @_;
    my @elements = $tree->look_down(_tag => $selector);
    return map { $_->as_text } @elements;
}

sub extract_meta {
    my ($self, $tree) = @_;
    my %meta;
    
    my @meta_tags = $tree->look_down(_tag => 'meta');
    foreach my $tag (@meta_tags) {
        my $name = $tag->attr('name') || $tag->attr('property');
        my $content = $tag->attr('content');
        $meta{$name} = $content if $name && $content;
    }
    
    return \%meta;
}

sub scrape {
    my ($self, $url, $selectors) = @_;
    my $html = $self->fetch($url);
    my $tree = $self->parse_html($html);
    
    my %data;
    foreach my $key (keys %$selectors) {
        $data{$key} = $self->extract_text($tree, $selectors->{$key});
    }
    
    $tree->delete;
    return \%data;
}

1;
