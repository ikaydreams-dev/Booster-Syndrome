#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Time::HiRes qw(time);

package HealthMonitor;

sub new {
    my ($class, $config) = @_;
    my $self = {
        ua => LWP::UserAgent->new(timeout => 10),
        endpoints => $config->{endpoints} || [],
        alerts => [],
    };
    return bless $self, $class;
}

sub check_endpoint {
    my ($self, $endpoint) = @_;

    my $start_time = time();
    my $response = $self->{ua}->get($endpoint->{url});
    my $duration = (time() - $start_time) * 1000;

    return {
        url => $endpoint->{url},
        status => $response->code,
        success => $response->is_success,
        duration_ms => sprintf("%.2f", $duration),
        timestamp => time(),
    };
}

sub check_all {
    my ($self) = @_;
    my @results;

    foreach my $endpoint (@{$self->{endpoints}}) {
        my $result = $self->check_endpoint($endpoint);
        push @results, $result;

        if (!$result->{success}) {
            $self->alert($endpoint->{url}, $result->{status});
        }
    }

    return \@results;
}

sub alert {
    my ($self, $url, $status) = @_;

    my $alert = {
        url => $url,
        status => $status,
        timestamp => time(),
        message => "Endpoint $url returned status $status",
    };

    push @{$self->{alerts}}, $alert;
    print STDERR "ALERT: $alert->{message}\n";
}

sub get_alerts {
    my ($self) = @_;
    return $self->{alerts};
}

sub clear_alerts {
    my ($self) = @_;
    $self->{alerts} = [];
}

sub generate_report {
    my ($self, $results) = @_;

    my $total = scalar @$results;
    my $successful = scalar grep { $_->{success} } @$results;
    my $failed = $total - $successful;

    return {
        total_checks => $total,
        successful => $successful,
        failed => $failed,
        success_rate => $total > 0 ? ($successful / $total) * 100 : 0,
        checks => $results,
    };
}

1;
