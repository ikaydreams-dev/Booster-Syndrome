#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Time::HiRes qw(time);

my $services = [
    { name => 'auth-service', url => 'http://localhost:3000/health' },
    { name => 'gateway', url => 'http://localhost:8080/health' },
    { name => 'user-service', url => 'http://localhost:3001/health' },
    { name => 'analytics-service', url => 'http://localhost:8001/health' },
];

sub check_service {
    my ($service) = @_;
    my $ua = LWP::UserAgent->new(timeout => 5);
    my $start = time();

    my $response = $ua->get($service->{url});
    my $duration = (time() - $start) * 1000;

    return {
        name => $service->{name},
        status => $response->is_success ? 'UP' : 'DOWN',
        response_time => sprintf("%.2f ms", $duration),
        status_code => $response->code,
    };
}

sub monitor_all {
    print "=== Service Health Check ===\n";
    print localtime() . "\n\n";

    my @results;
    foreach my $service (@$services) {
        my $result = check_service($service);
        push @results, $result;

        printf "%-20s %-10s %-15s %d\n",
            $result->{name},
            $result->{status},
            $result->{response_time},
            $result->{status_code};
    }

    return \@results;
}

sub save_metrics {
    my ($results) = @_;
    my $json = JSON->new->utf8->pretty;
    my $data = {
        timestamp => time(),
        services => $results,
    };

    open my $fh, '>>', 'metrics.json' or die "Cannot open file: $!";
    print $fh $json->encode($data);
    close $fh;
}

while (1) {
    my $results = monitor_all();
    save_metrics($results);

    print "\n" . "=" x 60 . "\n\n";
    sleep 30;
}
