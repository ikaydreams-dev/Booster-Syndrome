package TextProcessing;

use strict;
use warnings;

# Word count
sub word_count {
    my ($text) = @_;
    my @words = split /\s+/, $text;
    return scalar @words;
}

# Character frequency
sub char_frequency {
    my ($text) = @_;
    my %freq;
    
    foreach my $char (split //, $text) {
        $freq{$char}++;
    }
    
    return \%freq;
}

# Remove duplicates
sub remove_duplicates {
    my (@array) = @_;
    my %seen;
    return grep { !$seen{$_}++ } @array;
}

# Find and replace
sub find_replace {
    my ($text, $find, $replace) = @_;
    $text =~ s/$find/$replace/g;
    return $text;
}

# Extract emails
sub extract_emails {
    my ($text) = @_;
    my @emails = $text =~ /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g;
    return @emails;
}

# Extract URLs
sub extract_urls {
    my ($text) = @_;
    my @urls = $text =~ /https?:\/\/[^\s]+/g;
    return @urls;
}

# Title case
sub title_case {
    my ($text) = @_;
    $text = lc($text);
    $text =~ s/\b(\w)/\u$1/g;
    return $text;
}

# Snake case to camel case
sub snake_to_camel {
    my ($text) = @_;
    $text =~ s/_([a-z])/\u$1/g;
    return $text;
}

# Camel case to snake case
sub camel_to_snake {
    my ($text) = @_;
    $text =~ s/([A-Z])/_\l$1/g;
    $text =~ s/^_//;
    return $text;
}

# Truncate text
sub truncate {
    my ($text, $length, $suffix) = @_;
    $suffix //= '...';
    
    if (length($text) > $length) {
        return substr($text, 0, $length) . $suffix;
    }
    
    return $text;
}

1;
