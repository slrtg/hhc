#!usr/bin/perl
use strict;
use warnings;
use IO::File;
use Cwd;
use IO::Uncompress::Unzip qw(unzip $UnzipError);
use File::Copy qw(copy move);
use File::Path qw(mkpath);
use File::Spec::Functions qw(splitpath);

parse_sid();

sub parse_sid{
  my $sid;
  my $sid_fh;
  my $nodestatus;
  my $nodehealth;
  my $clustersize;
  my $clustermacid;
  my $node1macid;
  my $node2macid;
  my $node1model;
  my $node2model;
  my $node1fw;
  my $node2fw;
  my $node1serial;
  my $node2serial;
  my $evsip = "192.0.2.2";
  #print "Admin EVS IP: ";
  #chomp(my $evsip = <STDIN>);
  my $sid_path = "SiDiagnostics/diagshowall/$evsip";
  opendir my $SiDdiag, "$sid_path" or die "Could not open the SiDiagnostic: $!";
  foreach my $file (readdir $SiDdiag){ 
    $sid_fh = $file if $file =~/.txt$/;
  }

  {
    open my $sidlines, "$sid_path/$sid_fh" or die "Couldn't open storage diagnostic: $!";
    local $/;
    $sid = <$sidlines>;
    close($sidlines)
  }
  # Retrieve node status and health
  if ($sid =~ /<cluster-show for pnode 1>\nOverall Status = (.*?)\nCluster Health = (.*?)\n/){
    $nodestatus = $1;
    $nodehealth = $2;
    print "Node 1:\n";
    print "Overall status: $nodestatus\n";
    print "Cluster health: $nodehealth\n"; 
  }
  # Retrieve cluster size
  if ($sid =~ /Cluster Size = (.)\n/){
    $clustersize = $1;
    print "Cluster size: $clustersize\n";
  }

  # Retrieve cluster mac id
  if ($sid =~/<cluster-getmac for pnode 1>\ncluster MAC: (..-..-..-..-..-..)\n/){
    $clustermacid = $1;
    print "Cluster MAC ID: $clustermacid\n";
  }
  
  
}