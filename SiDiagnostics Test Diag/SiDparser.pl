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

  print "\nHNAS NODE INFO\n";

  #Server Uptime
  if ($sid =~/<status for pnode 1>.*?Server uptime:(.*?)\n/s){
    $node1uptime = $1;
    print "Node 1 Server Uptime: $node1uptime\n";
  }
  if ($sid =~/<status for pnode 2>.*?Server uptime:(.*?)\n/s){
    $node2uptime = $1;
    print "Node 2 Server Uptime: $node2uptime\n";
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

  #NETWORK INFO

  print "\nNETWORK INFO\n";

  #Historical TCP Statistics
  my $rxstats1;
  my $rxstats2;
  my $totalpackets1;
  my $totalpackets2;
  my $goodpackets1;
  my $goodpackets2;

  if ($sid =~/<tcpstats for pnode 1>.*?Total Packets: (.*?)\n/s){
    $totalpackets1 = $1;
  }
  if ($sid =~/<tcpstats for pnode 2>.*?Total Packets: (.*?)\n/s){
    $totalpackets2 = $1;
  }
  if ($sid =~/<tcpstats for pnode 1>.*?Good Packets: (.*?)\n/s){
    $goodpackets1 = $1;
  }
  if ($sid =~/<tcpstats for pnode 2>.*?Good Packets: (.*?)\n/s){
    $goodpackets2 = $1;
  }

  #Node 1

  if ($totalpackets1/$goodpackets1 < 1.000){
    $rxstats1 = "OK";
  } elsif ($totalpackets1/$goodpackets1 > 2.000){
    $rxstats1 = "Critical";
  } else {
    $rxstats1 = "Needs Attention";
  }
  print "Node 1 RX Stats: Dropped Packets: $rxstats1\n";

  #Node 2

  if ($totalpackets2/$goodpackets2 < 1.000){
    $rxstats2 = "OK";
  } elsif ($totalpackets2/$goodpackets2 > 2.000){
    $rxstats2 = "Critical";
  } else {
    $rxstats2 = "Needs Attention";
  }
  print "Node 2 RX Stats: Dropped Packets: $rxstats2\n";

  #Ethernet Settings
  my $ssca1;
  my $ssca2;
  my $ssidle1;
  my $ssidle2;
  my $tcpws1;
  my $tcpws2;
  my $ess1;
  my $ess2;

  if ($sid =~/<ipeng.*?pnode 1>.*?ca:.*?(\w{2,3}).*?\w*?.*?\n/s){
    $ssca1 = $1;
  }
  if ($sid =~/<ipeng.*?pnode 2>.*?ca:.*?(\w{2,3}).*?\w*?.*?\n/s){
    $ssca2 = $1;
  }
  if ($sid =~/<ipeng.*?pnode 1>.*?idle:.*?(\w{2,3}).*?\w*?.*?\n/s){
    $ssidle1 = $1;
  }
  if ($sid =~/<ipeng.*?pnode 2>.*?idle:.*?(\w{2,3}).*?\w*?.*?\n/s){
    $ssidle2 = $1;
  }
  if ($sid =~/<ipeng.*?pnode 1>.*?TCP Window Scaling enabled:.*?(\w{2,3}).*?\w*?.*?\n/s){
    $tcpws1 = $1;
  }
  if ($sid =~/<ipeng.*?pnode 2>.*?TCP Window Scaling enabled:.*?(\w{2,3}).*?\w*?.*?\n/s){
    $tcpws2 = $1;
  }

  if ($ssca1 =~ "Yes" && $ssidle1 =~ "Yes" && $tcpws1 =~ "Yes"){
    $ess1 = "Ok";
  } else {
    $ess1 = "Needs Attention";
  }
  print "Node 1 Ethernet Settings Status: $ess1\n";

  if ($ssca2 =~ "Yes" && $ssidle2 =~ "Yes" && $tcpws2 =~ "Yes"){
    $ess2 = "Ok";
  } else {
    $ess2 = "Needs Attention";
  }
  print "Node 2 Ethernet Settings Status: $ess2\n";

  #HNAS SD, SP, AND FS HEALTH
  print "\nHNAS SYSTEM DRIVE, STORAGE POOL AND FILE SYSTEM HEALTH\n";

    #SYSTEM DRIVES
  #SD Status  
  my $sdstatus1 = "OK";
  my $sdstatus2 = "OK";
  
  if ($sid =~/<sd-list --superflush.*?pnode 1>.*?-\n(.*?)<s/s){
    for ($1 =~m/.*?\d+ *?(\w+).*?\n/g){
      $sdstatus1 = $_ if $sdstatus1 gt "$_";
    }
    $sdstatus1 = "Need Attention" if $sdstatus1 ne "OK";
    print "Node 1 SD Status: $sdstatus1\n";
  }

  if ($sid =~/<sd-list --superflush.*?pnode 2>.*?-\n(.*?)<s/s){
    for ($1 =~m/.*?\d+ *?(\w+).*?\n/g){
      $sdstatus2 = $_ if $sdstatus2 gt "$_";
    }
    $sdstatus2 = "Need Attention" if $sdstatus2 ne "OK";
    print "Node 2 SD Status: $sdstatus2\n";
  }
  #SD Allowed Status
  my $sdallow1 = "Yes";
  my $sdallow2 = "Yes";
  if ($sid =~/<sd-list --superflush.*?pnode 1>.*?-\n(.*?)<s/s){
    for ($1 =~m/.*?\d+ *?\w+ *?(\w+).*?\n/g){
      $sdallow1 = $_ if $sdallow1 gt "$_";
    }
    $sdallow1 = "Need Attention" if $sdallow1 ne "Yes";
    $sdallow1 = "OK" if $sdallow1 eq "Yes";
    print "Node 1 SD Allowed Status: $sdallow1\n";
  }
  if ($sid =~/<sd-list --superflush.*?pnode 2>.*?-\n(.*?)<s/s){
    for ($1 =~m/.*?\d+ *?\w+ *?(\w+).*?\n/g){
      $sdallow2 = $_ if $sdallow2 gt "$_";
    }
    $sdallow2 = "Need Attention" if $sdallow2 ne "Yes";
    $sdallow2 = "OK" if $sdallow2 eq "Yes";
    print "Node 2 SD Allowed Status: $sdallow2\n";
  }
  #SD Superflush Settings Check
  my $sfstatus1 = "OK";
  my $sfstatus2 = "OK";
  if ($sid =~/<sd-list --superflush.*?pnode 1>.*?-\n.*?\w\w-\d\d +?(\d.*?K)\n/s){
    my $superflush1 = $1;
    if ($sid =~/<sd-list --superflush.*?pnode 1>.*?-\n(.*?)<s/s){
      for ($1 =~m/.*?\d+ *?\w+.*?\w\w-\d\d *?(\d.*?K)\n/g){
        $sfstatus1 = "Needs Attention" if $_ ne $superflush1;
      }
    }
  }
  print "Node 1 Superflush Setting: $sfstatus1\n";

  if ($sid =~/<sd-list --superflush.*?pnode 2>.*?-\n.*?\w\w-\d\d +?(\d.*?K)\n/s){
    my $superflush2 = $1;
    if ($sid =~/<sd-list --superflush.*?pnode 2>.*?-\n(.*?)<s/s){
      for ($1 =~m/.*?\d+ *?\w+.*?\w\w-\d\d *?(\d.*?K)\n/g){
        $sfstatus2 = "Needs Attention" if $_ ne $superflush2;
      }
    }
  }
  print "Node 2 Superflush Setting: $sfstatus2\n"; 
  
  #Scsi Queue Depth
  my $sqdstatus1 = "OK";
  my $sqd1 = "32";
  my $sqdstatus2 = "OK";
  my $sqd2 = "32";

  if ($sid =~/<scsi-queue-depths for pnode 1>.*?-\n(.*?)<s/s){
    for ($1 =~ m/.*?\d+.*?\d+.*?(\d+).*?\n/sg){
      $sqdstatus1 = "Needs Attention" if $sqd1 ne $_;
    }
    print "Node 1 SCSI Queue Depth: $sqdstatus1\n";
  }

  if ($sid =~/<scsi-queue-depths for pnode 2>.*?-\n(.*?)<s/s){
    for ($1 =~ m/.*?\d+.*?\d+.*?(\d+).*?\n/sg){
      $sqdstatus2 = "Needs Attention" if $sqd2 ne $_;
    }
    print "Node 2 SCSI Queue Depth: $sqdstatus2\n";
  }
  
  #Storage Back-End Backlog
  my $mqr1 = 0;
  my $mqr2 = 0;
  my $mqw1 = 0;
  my $mqw2 = 0;

  #Reads for node 1
  if ($sid =~/<devinfo -a for pnode 1>.*?-\n(.*?)<d/s){
    for ($1 =~ m/ *?\d+ *?\w+ *?\d+ *?\d+ *?\d+ *?\d+ *?\d+ *?(\d+) *?\d+ *? \d+.*?\n/g){
      $mqr1 = $_ if $mqr1 < $_;
    }
    print "Node 1 Highest Number of Queued Reads:  $mqr1\n";
  }
  #Writes for node 1
  if ($sid =~/<devinfo -a for pnode 1>.*?-\n(.*?)<d/s){
    for ($1 =~ m/ *?\d+ *?\w+ *?\d+ *?\d+ *?\d+ *?\d+ *?\d+ *?\d+ *?\d+ *? (\d+).*?\n/g){
      $mqw1 = $_ if $mqw1 < $_;
    }
    print "Node 1 Highest Number of Queued Writes: $mqw1\n";
  }

  #Reads for node 2
  if ($sid =~/<devinfo -a for pnode 2>.*?-\n(.*?)\n<scsi/s){
    for ($1 =~ m/ *?\d+ *?\w+ *?\d+ *?\d+ *?\d+ *?\d+ *?\d+ *?(\d+) *?\d+ *? \d+.*?\n/g){
      $mqr2 = $_ if $mqr2 < $_;
    }
    print "Node 2 Highest Number of Queued Reads:  $mqr2\n";
  }
  #Writes for node 2
  if ($sid =~/<devinfo -a for pnode 2>.*?-\n(.*?)\n<scsi/s){
    for ($1 =~ m/ *?\d+ *?\w+ *?\d+ *?\d+ *?\d+ *?\d+ *?\d+ *?\d+ *?\d+ *? (\d+).*?\n/g){
      $mqw2 = $_ if $mqw2 < $_;
    }
    print "Node 2 Highest Number of Queued Writes: $mqw2\n";
  }

  #STORAGE POOL STATUS
  #Storage Pool Status
  my $sps1 = "";
  my $sps2 = "";
  my $spyes1 = 0;
  my $spyes2 = 0;
  my $spno1 = 0;
  my $spno2 = 0;
  if ($sid =~/<span-list -fsv for pnode 1>\n(.*?)<span-list -fsv for pnode 2>\n/s){
    for ($1 =~m/.*?SP-\d\d.*?(\w+).*?\n/gs){
      $_ eq "No" ? $spno1++ : $spyes1++
    } 
    if ($spno1 == 0){
      $sps1 = "OK";
    } elsif ($spyes1 == 0){
      $sps1 = "Critical";
    } else {
      $sps1 = "Need Attention";
    }
  print "Node 1 Storage Pool Status: $sps1\n";  
  }

  if ($sid =~/<span-list -fsv for pnode 2>\n(.*?)<s/s){
    for ($1 =~m/.*?SP-\d\d.*?(\w+).*?\n/gs){
      $_ eq "No" ? $spno2++ : $spyes2++
    } 
    if ($spno2 == 0){
      $sps2 = "OK";
    } elsif ($spyes2 == 0){
      $sps2 = "Critical";
    } else {
      $sps2 = "Need Attention";
    }
  print "Node 2 Storage Pool Status: $sps2\n";  
  }

  #Storage Capacity
  my $spfree1 = 100;
  my $spcap1 = "";
  if ($sid =~/<span-list -fsv for pnode 1>\n(.*?)<span-list -fsv for pnode 2>\n/s){
    for ($1 =~ m/.*?SP-\d\d.*?\w+.*?(\d+)%.*?\n/gs){
      $spfree1 = $_ if $_ < $spfree1;
    }
  $spcap1 = 100 - $spfree1 ."%";   
  print "Node 1 Pool Capacity Closest to 100%: $spcap1\n";  
  }

  my $spfree2 = 100;
  my $spcap2 = "";
  if ($sid =~/<span-list -fsv for pnode 2>\n(.*?)<s/s){
    for ($1 =~ m/.*?SP-\d\d.*?\w+.*?(\d+)%.*?\n/gs){
      $spfree2 = $_ if $_ < $spfree2;
    }
  $spcap2 = 100 - $spfree2 ."%";   
  print "Node 2 Pool Capacity Closest to 100%: $spcap2\n";  
  }

  #Stripe Sets
  my $stripestatus1 = "";
  my $stripestatus2 = "";
  my $stripeok1 = 0;
  my $stripeok2 = 0;
  my $stripecritical1 = 0;
  my $stripecritical2 = 0;
  my $stripena1 = 0;
  my $stripena2 = 0;
  if ($sid =~/<span-list -fsv for pnode 1>\n(.*?)<span-list -fsv for pnode 2>\n/s){
    for ($1 =~ m/Set \d+:.*?(\d+).*?\n/gs){
      if ($_ >= 4){
        $stripeok1++;
      } elsif ($_ == 1){
        $stripecritical1++;
      } else {
        $stripena1++;
      }
    }
  if ($stripecritical1 > 0){
    $stripestatus1 = "Critical";
  }  elsif ($stripena1 == 0 && $stripecritical1 == 0){
    $stripestatus1 = "OK"
  } else {
    $stripestatus1 = "Needs Attention";
  }
  print "Node 1 Stripe Status: $stripestatus1\n";
  }

  if ($sid =~/<span-list -fsv for pnode 2>\n(.*?)<s/s){
    for ($1 =~ m/Set \d+:.*?(\d+).*?\n/gs){
      if ($_ >= 4){
        $stripeok2++;
      } elsif ($_ == 1){
        $stripecritical2++;
      } else {
        $stripena2++;
      }
    }
  if ($stripecritical2 >= 1){
    $stripestatus2 = "Critical";
  }  elsif ($stripena2 == 0 && $stripecritical2 == 0){
    $stripestatus2 = "OK"
  } else {
    $stripestatus2 = "Needs Attention";
  }
  print "Node 2 Stripe Status: $stripestatus2\n";
  }

  

  #Meets BP
  my $meetsbp1 = "";
  my $meetsbp2 = "";
  if ($sps1 eq "OK" && $stripestatus1 eq "OK"){
    $meetsbp1 = "OK";
  } elsif ($sps1 eq "Critical" || $stripestatus1 eq "Critical"){
    $meetsbp1 = "Critical";
  } else {
    $meetsbp1 = "Needs Attention";
  }

  print "Node 1 BP: $meetsbp1\n";


  if ($sps2 eq "OK" && $stripestatus2 eq "OK"){
    $meetsbp2 = "OK";
  } elsif ($sps2 eq "Critical" || $stripestatus2 eq "Critical"){
    $meetsbp2 = "Critical";
  } else {
    $meetsbp2 = "Needs Attention";
  }

  print "Node 2 BP: $meetsbp2\n";

  #FILE SYSTEM HEALTH CHECK

  #File System Status
  my $fsstatus1 = "";
  my $fsstatus2 = "";
  my $fsok1 = 0;
  my $fsok2 = 0;
  my $fscritical1 = 0;
  my $fscritical2 = 0;

  if ($sid =~ /<span-list -fsv for pnode 1>\n(.*?)<span-list -fsv for pnode 2>\n/s){
    for ($1 =~m/.*?fs.*? +?(\w+),.*?\n/gs){
      if ($_ eq "UnMnt" || $_ eq "NoEVS"){
        $fscritical1++;
      } else {
        $fsok1++;
      }
    }
  }
  if ($fsok1 == 0){
    $fsstatus1 = "Critical";
  } elsif ($fscritical1 == 0){
    $fsstatus1 = "OK";
  } else {
    $fsstatus1 = "Needs Attention";
  }
  print "Node 1 File System Status: $fsstatus1\n";

  if ($sid =~ /<span-list -fsv for pnode 2>\n(.*?)<s/s){
    for ($1 =~m/.*?fs.*? +?(\w+),.*?\n/gs){
      if ($_ eq "UnMnt" || $_ eq "NoEVS"){
        $fscritical2++;
      } else {
        $fsok2++;
      }
    }
  }
  if ($fsok2 == 0){
    $fsstatus2 = "Critical";
  } elsif ($fscritical2 == 0){
    $fsstatus2 = "OK";
  } else {
    $fsstatus2 = "Needs Attention";
  }
  print "Node 2 File System Status: $fsstatus2\n";
}

