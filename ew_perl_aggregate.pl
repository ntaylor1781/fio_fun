#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Getopt::ArgParse;

my $args = validate_args();
print Dumper($args);
my $logfile = $args->{'logfile'};
my @read;
my @write;
my $read_stats;
my $write_stats;
my $general_stats;

open (my $fh, '<', $logfile) or die "Could not open file: $logfile\n $!\n";
while (my $row = <$fh>) {
  chomp $row;
  my ($add_read) = $row =~ /(read\ .+)/s;
  my ($add_write) = $row =~ /(write:\ io.+)/s;
  push @read, $add_read if $add_read;
  push @write, $add_write if $add_write;
  ($read_stats) = $1 if $row =~ (/(READ:.+)/s);
  ($write_stats) = $1 if $row =~ (/(WRITE:.+)/s);
  ($general_stats) = $row =~ /(\S.+util.+)$/s;
}
close $fh;

my $read_speed_kb = grab({string => $read_stats, search => 'aggrb'});
my $write_speed_kb = grab({string => $write_stats, search => 'aggrb'});
my $read_speed_mb = $read_speed_kb / 1024;
my $write_speed_mb = $write_speed_kb / 1024;

my $avg_read = aggregate(@read);
my $avg_write = aggregate(@write);

print qq{  Read Stats:
    Average read IO:        $avg_read->{'io'}MB,
    Average read IOPS:      $avg_read->{'iops'},
    Average read speed:     $read_speed_mb MB/s,
    Average runtime of job: $avg_read->{'runt'} msec\n
};
print qq{  Write Stats:
    Average write IO:       $avg_write->{'io'}MB,
    Average write IOPS:     $avg_write->{'iops'},
    Average write speed:    $write_speed_mb MB/s,
    Average runtime of job: $avg_write->{'runt'} msec\n
};
print "  $read_stats\n";
print "  $write_stats\n";
print "  General Stats: $general_stats\n";

sub aggregate {
  my @array = @_;
  my $hash;
  my $io = 0;
  my $iops = 0;
  my $runt = 0;

  foreach my $line (@array) {
    $io += grab({string => $line, search => 'io'});
    $iops += grab({string => $line, search => 'iops'});
    $runt += grab({string => $line, search => 'runt'});
  }

  my $num_entries = scalar(@array);
  $hash->{'io'} = $io / $num_entries;
  $hash->{'iops'} = $iops / $num_entries;
  $hash->{'runt'} = $runt / $num_entries;

  return $hash;
}

sub grab {
  my $args = shift;
  my $string = $args->{'string'};
  my $search = $args->{'search'};
  my ($temp_resp) = $string =~ /($search=[0-9]+)/s;
  return (split'=', $temp_resp)[1];
}

sub validate_args {
    my $ap = Getopt::ArgParse->new_parser(
        prog        => 'Aggregate',
        description => 'Aggregates fio stats across multiple jobs',
    );
    $ap->add_arg('--logfile', '-l', required => 1, help => 'The fio output file you which to parse', type => 'Scalar');
    my $resp = $ap->parse_args();
    return $resp->{'-values'};
}
