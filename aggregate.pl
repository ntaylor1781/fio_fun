#!/usr/bin/perl
use Data::Dumper;

my $output = '/etc/fio/output.log';
my @read;
my @write;
my $stats;

open (my $fh, '<', $output) or die "Could not open file: $output\n $!\n";
while (my $row = <$fh>) {
  chomp $row;
  my ($add_read) = $row =~ /(read\ .+)/s;
  my ($add_write) = $row =~ /(write:.+)/s;
  push @read, $add_read if $add_read;
  push @write, $add_write if $add_write;
  ($stats) = $row =~ /(\S.+util.+)$/s;
}
close $fh;

my $avg_read = aggregate(@read);
my $avg_write = aggregate(@write);

print qq{  Read Stats:
    Average read IO:        $avg_read->{'io'}MB,
    Average read IOPS:      $avg_read->{'iops'},
    Average runtime of job: $avg_read->{'runt'} msec\n
};
print qq{  Write Stats:
    Average write IO:       $avg_write->{'io'}MB,
    Average write IOPS:     $avg_write->{'iops'},
    Average runtime of job: $avg_write->{'runt'} msec\n
};
print "  General Stats: $stats\n";

sub aggregate {
  my @array = @_;
  my $hash;
  my $io;
  my $iops;
  my $runt;

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
