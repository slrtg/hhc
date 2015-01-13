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

  # IMPORTANT: Don't forget to delete and uncomment below for user inputted evs
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

  # CLUSTER HEALTH
  my $nodestatus;
  my $nodehealth;
  my $clustersize;
  my $clustermacid;

  print "\nCLUSTER HEALTH\n";
  # Retrieve cluster size
  if ($sid =~ /Cluster Size = (.)\n/){
    $clustersize = $1;
    print "Cluster size: $clustersize\n";
  }
  # Retrieve node status and health
  if ($sid =~ /<cluster-show for pnode 1>\nOverall Status = (.*?)\nCluster Health = (.*?)\n/){
    $nodestatus = $1;
    $nodehealth = $2;
    print "Overall status: $nodestatus\n";
    print "Cluster health: $nodehealth\n"; 
  }
  # Retrieve cluster mac id
  if ($sid =~/<cluster-getmac for pnode 1>\ncluster MAC: (..-..-..-..-..-..)\n/){
    $clustermacid = $1;
    print "Cluster MAC ID: $clustermacid\n";
  }

  #HNAS MODEL AND FIRMWARE
  my $node1macid;
  my $node2macid;
  my $node1model;
  my $node2model;
  my $node1fw;
  my $node2fw;
  my $node1serial;
  my $node2serial;

  print "\nNODE MAC, MODEL, FIRMWARE, and SERIAL\n";
  
  # Retrieve MAC ID
  if ($sid =~ /<getmacid for pnode 1>\nMAC ID is (..-..-..-..-..-..)\n/){
    $node1macid = $1;
    print "Node 1 MAC ID: $node1macid\n";
  }

  if ($sid =~ /<getmacid for pnode 2>\nMAC ID is (..-..-..-..-..-..)\n/){
    $node2macid = $1;
    print "Node 2 MAC ID: $node2macid\n";
  }

  #Retrieve Model
  if ($sid =~/<ver for pnode 1>\n\nModel: (.*?)\n/){
    $node1model = $1;
    print "Node 1 model: $node1model\n";
  }
  if ($sid =~/<ver for pnode 2>\n\nModel: (.*?)\n/){
    $node2model = $1;
    print "Node 2 model: $node2model\n";
  }

  #Retrieve Firmware Ver
  if ($sid =~/<ver for pnode 1>\n\n.*?\n\nSoftware: (.*?) /){
    $node1fw = $1;
    print "Node 1 Firmware: $node1fw\n";
  }
  if ($sid =~/<ver for pnode 2>\n\n.*?\n\nSoftware: (.*?) /){
    $node2fw = $1;
    print "Node 2 Firmware: $node2fw\n";
  }

  #Retrieve Serial
  if ($sid =~/<ver for pnode 1>\n\n.*?\n\n.*?\n\n.*? Platform \((.*?)\)\n/){
    $node1serial = $1;
    print "Node 1 Serial: $node1serial\n";
  }
  if ($sid =~/<ver for pnode 2>\n\n.*?\n\n.*?\n\n.*? Platform \((.*?)\)\n/){
    $node2serial = $1;
    print "Node 2 Serial: $node2serial\n";
  }

  #HNAS NODE OVERALL STATUS
  my $cis1;
  my $cis2;
  my $mns1;
  my $mns2;
  my $qds1;
  my $qds2;
  my $pss1_1;
  my $pss1_2;
  my $pss2_1;
  my $pss2_2;
  my $cbs1;
  my $cbs2;
  my $cfm1_1;
  my $cfm1_2;
  my $cfm2_1;
  my $cfm2_2;
  my $psfm1_1;
  my $psfm1_2;
  my $psfm2_1;
  my $psfm2_2;
  my $cds1_0;
  my $cds1_1;
  my $cds1_2;
  my $cds1_3;
  my $cds2_0;
  my $cds2_1;
  my $cds2_2;
  my $cds2_3;

  print "\nOVERALL STATUS\n";
  #Cluster Interconnect status
  if ($sid =~/<status for pnode 1>.*?Cluster Interconnect: (.*?)\n/s){
    $cis1 = $1;
    print "Node 1 Cluster Interconect Status:  $cis1\n";
  }
  if ($sid =~/<status for pnode 2>.*?Cluster Interconnect: (.*?)\n/s){
    $cis2 = $1;
    print "Node 2 Cluster Interconect Status:  $cis2\n";
  }
  #Management Network Status
  if ($sid =~/<status for pnode 1>.*?Management Network: (.*?)\n/s){
    $mns1 = $1;
    print "Node 1 Management Network Status: $mns1\n";
  }
  if ($sid =~/<status for pnode 2>.*?Management Network: (.*?)\n/s){
    $mns2 = $1;
    print "Node 2 Management Network Status: $mns2\n";
  }
  #Quorum Device Status
  if ($sid =~/<status for pnode 1>.*?Quorum Device: (.*?)\n/s){
    $qds1 = $1;
    print "Node 1 Quorum Device Status: $qds1\n";
  }
  if ($sid =~/<status for pnode 2>.*?Quorum Device: (.*?)\n/s){
    $qds2 = $1;
    print "Node 2 Quorum Device Status: $qds2\n";
  }
  #Power Supply Status
  if ($sid =~/<status for pnode 1>.*?Power supply status:.*?1:(.*?)\n.*?2:(.*?)\n/s){
    $pss1_1 = $1;
    $pss1_2 = $2;
    print "Node 1 Power Supply Status:\n\tUnit 1: $pss1_1\n\tUnit 2: $pss1_2\n";
  }
  if ($sid =~/<status for pnode 2>.*?Power supply status:.*?1:(.*?)\n.*?2:(.*?)\n/s){
    $pss2_1 = $1;
    $pss2_2 = $2;
    print "Node 2 Power Supply Status:\n\tUnit 1: $pss2_1\n\tUnit 2: $pss2_2\n";
  }
  #Chassis Battery Status
  if ($sid =~/<status for pnode 1>.*?Chassis battery status:\nUnit 1:(.*?)\n/s){
    $cbs1 = $1;
    print "Node 1 Chassis Battery Status:\n\tUnit 1: $cbs1\n";
  }
  if ($sid =~/<status for pnode 2>.*?Chassis battery status:\nUnit 1:(.*?)\n/s){
    $cbs2 = $1;
    print "Node 2 Chassis Battery Status:\n\tUnit 1: $cbs2\n";
  }
  #Chassis Fan Module
  if ($sid =~/<status for pnode 1>.*?Fan status:.*? module (.): (.*?)\n.*? module (.): (.*?)\n/s){
    $cfm1_1 = $2;
    $cfm1_2 = $4;
    print "Node 1 Chassis Fan Module Status:\n\tModule $1: $cfm1_1\n\tModule $3: $cfm1_2\n";
  }
  if ($sid =~/<status for pnode 2>.*?Fan status:.*? module (.): (.*?)\n.*? module (.): (.*?)\n/s){
    $cfm2_1 = $2;
    $cfm2_2 = $4;
    print "Node 2 Chassis Fan Module Status:\n\tModule $1: $cfm2_1\n\tModule $3: $cfm2_2\n";
  }
 
  #Power Supply Fan Module
  if ($sid =~/<status for pnode 1>.*?Fan status:.*? PSU(.) fan: (.*?)\n.*?PSU(.) fan: (.*?)\n/s){
    $psfm1_1 = $2;
    $psfm1_2 = $4;
    print "Node 1 PSU Fan Module Status:\n\tPSU$1: $psfm1_1\n\tPSU$3: $psfm1_2\n";
  }
  if ($sid =~/<status for pnode 2>.*?Fan status:.*? PSU(.) fan: (.*?)\n.*?PSU(.) fan: (.*?)\n/s){
    $psfm2_1 = $2;
    $psfm2_2 = $4;
    print "Node 2 PSU Fan Module Status:\n\tPSU$1: $psfm2_1\n\tPSU$3: $psfm2_2\n";
  }
  #Chassis Disk Status
  if ($sid =~/<status for pnode 1>.*?Chassis disk status:.*?0: (.*?)\n.*?1: (.*?)\n.*?2: (.*?)\n.*?3: (.*?)\n/s){
    $cds1_0 = $1;
    $cds1_1 = $2;
    $cds1_2 = $3;
    $cds1_3 = $4;
    print "Node 1 Chassis Disk Status:\n\tmd0: $cds1_0\n\tmd1: $cds1_1\n\tmd2: $cds1_2\n\tmd3: $cds1_3\n";
  }
  if ($sid =~/<status for pnode 2>.*?Chassis disk status:.*?0: (.*?)\n.*?1: (.*?)\n.*?2: (.*?)\n.*?3: (.*?)\n/s){
    $cds2_0 = $1;
    $cds2_1 = $2;
    $cds2_2 = $3;
    $cds2_3 = $4;
    print "Node 2 Chassis Disk Status:\n\tmd0: $cds2_0\n\tmd1: $cds2_1\n\tmd2: $cds2_2\n\tmd3: $cds2_3\n";
  }

  #HNAS NODE INFO
  my $node1uptime;
  my $node2uptime;
  my $bfd1;
  my $bfd2;
  my $fcls1;
  my $fcls2;

  #Server Uptime
  if ($sid =~/<status for pnode 1>.*?Server uptime:(.*?)\n/s){
    $node1uptime = $1;
    print "Node 1 Server Uptime:   $node1uptime\n";
  }
  if ($sid =~/<status for pnode 2>.*?Server uptime:(.*?)\n/s){
    $node2uptime = $1;
    print "Node 2 Server Uptime:   $node2uptime\n";
  }
  #Battery Fitted Date
  if ($sid =~/<ver -h for pnode 1>.*?Battery fitted date:(.*?)\n/s){
    $bfd1 = $1;
    print "Node 1 Battery Fitted Date:$bfd1\n";
  }
  if ($sid =~/<ver -h for pnode 2>.*?Battery fitted date:(.*?)\n/s){
    $bfd2 = $1;
    print "Node 2 Battery Fitted Date:$bfd2\n";
  }
  #FC-Link-Status
  if ($sid =~/<fc-link-status for pnode 1>\n(.*?)\n</s){
    $fcls1 = $1;
    print "Node 1 FC Link Status:\n$fcls1\n";
  }
  if ($sid =~/<fc-link-status for pnode 2>\n(.*?)\n</s){
    $fcls2 = $1;
    print "Node 2 FC Link Status:\n$fcls2\n";
  }
}