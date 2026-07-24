#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes qw(time);
use JSON;

package HealthMonitor;

sub new {
    my ($class) = @_;
    my $self = {
        checks => {},
        results => {},
        last_run => 0
    };
    return bless $self, $class;
}

sub register_check {
    my ($self, $name, $check_sub) = @_;
    $self->{checks}{$name} = $check_sub;
}

sub run_check {
    my ($self, $name) = @_;

    unless (exists $self->{checks}{$name}) {
        return { status => 'error', message => 'Check not found' };
    }

    my $start_time = time();
    my $result = eval { $self->{checks}{$name}->() };
    my $duration = time() - $start_time;

    if ($@) {
        return {
            status => 'unhealthy',
            message => "Check failed: $@",
            duration => $duration
        };
    }

    return {
        status => $result ? 'healthy' : 'unhealthy',
        duration => $duration,
        timestamp => time()
    };
}

sub run_all_checks {
    my ($self) = @_;

    my %results;
    foreach my $name (keys %{$self->{checks}}) {
        $results{$name} = $self->run_check($name);
    }

    $self->{results} = \%results;
    $self->{last_run} = time();

    return \%results;
}

sub get_results {
    my ($self) = @_;
    return $self->{results};
}

sub is_healthy {
    my ($self) = @_;

    foreach my $result (values %{$self->{results}}) {
        return 0 if $result->{status} ne 'healthy';
    }

    return 1;
}

package SystemMetrics;

sub new {
    my ($class) = @_;
    my $self = {};
    return bless $self, $class;
}

sub cpu_usage {
    my ($self) = @_;

    if ($^O eq 'linux') {
        my $output = `top -bn1 | grep "Cpu(s)"`;
        if ($output =~ /(\d+\.\d+)%? id/) {
            return sprintf("%.2f", 100 - $1);
        }
    }

    return 0;
}

sub memory_usage {
    my ($self) = @_;

    if ($^O eq 'linux') {
        open my $fh, '<', '/proc/meminfo' or return {};

        my %mem;
        while (my $line = <$fh>) {
            if ($line =~ /^(\w+):\s+(\d+)/) {
                $mem{$1} = $2;
            }
        }
        close $fh;

        my $total = $mem{MemTotal} || 1;
        my $available = $mem{MemAvailable} || 0;
        my $used = $total - $available;

        return {
            total => $total,
            used => $used,
            available => $available,
            percent => sprintf("%.2f", ($used / $total) * 100)
        };
    }

    return {};
}

sub disk_usage {
    my ($self, $path) = @_;
    $path ||= '/';

    my $output = `df -h $path`;
    my @lines = split /\n/, $output;

    if (@lines > 1) {
        my @fields = split /\s+/, $lines[1];
        return {
            filesystem => $fields[0],
            size => $fields[1],
            used => $fields[2],
            available => $fields[3],
            percent => $fields[4]
        };
    }

    return {};
}

sub uptime {
    my ($self) = @_;

    if ($^O eq 'linux') {
        open my $fh, '<', '/proc/uptime' or return 0;
        my $line = <$fh>;
        close $fh;

        if ($line =~ /^(\d+\.\d+)/) {
            return $1;
        }
    }

    return 0;
}

sub network_stats {
    my ($self, $interface) = @_;
    $interface ||= 'eth0';

    my $rx_bytes = 0;
    my $tx_bytes = 0;

    if ($^O eq 'linux') {
        my $rx_file = "/sys/class/net/$interface/statistics/rx_bytes";
        my $tx_file = "/sys/class/net/$interface/statistics/tx_bytes";

        if (-f $rx_file) {
            open my $fh, '<', $rx_file;
            $rx_bytes = <$fh>;
            close $fh;
            chomp $rx_bytes;
        }

        if (-f $tx_file) {
            open my $fh, '<', $tx_file;
            $tx_bytes = <$fh>;
            close $fh;
            chomp $tx_bytes;
        }
    }

    return {
        interface => $interface,
        rx_bytes => $rx_bytes,
        tx_bytes => $tx_bytes
    };
}

package LogParser;

sub new {
    my ($class, $log_file) = @_;
    my $self = {
        log_file => $log_file,
        patterns => {}
    };
    return bless $self, $class;
}

sub add_pattern {
    my ($self, $name, $pattern) = @_;
    $self->{patterns}{$name} = qr/$pattern/;
}

sub parse {
    my ($self) = @_;

    my %results;
    foreach my $name (keys %{$self->{patterns}}) {
        $results{$name} = [];
    }

    open my $fh, '<', $self->{log_file} or die "Cannot open log file: $!";

    while (my $line = <$fh>) {
        chomp $line;

        foreach my $name (keys %{$self->{patterns}}) {
            if ($line =~ $self->{patterns}{$name}) {
                push @{$results{$name}}, {
                    line => $line,
                    matches => [$1, $2, $3, $4, $5]
                };
            }
        }
    }

    close $fh;
    return \%results;
}

sub count_matches {
    my ($self, $pattern) = @_;

    my $count = 0;
    open my $fh, '<', $self->{log_file} or return 0;

    while (my $line = <$fh>) {
        $count++ if $line =~ /$pattern/;
    }

    close $fh;
    return $count;
}

1;
