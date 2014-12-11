#!usr/bin/perl
use strict;
use warnings;
use IO::File;
use Cwd;
use IO::Uncompress::Unzip qw($UnzipError);
use File::Copy qw(copy);
use File::Path qw(mkpath);
use File::Spec::Functions qw(splitpath);

my $z_smu_diag;
my $zipped_diag;
my @diagfsr;

find_diags();
choose_diag();
unzip_diag();





#Open the CWD, find diagnostic files, and put them into Diagnostic Files Search Results (diagfsr)
sub find_diags{
    opendir my $diagdir, "." or die "$!";

    foreach my $file (readdir $diagdir){
       if($file =~ /^Diagnostics(.*)\.zip$/){
          push(@diagfsr, "$file");
       }

    }
}    








#Verifies how many diagnostic files were found and allows for user input on the results.
#Ultimately selects the HNAS zip that will be analyzed.
sub choose_diag{
    my $diagfsrnum = @diagfsr;
    if ($diagfsrnum < 1){
       print "There are no relevant files in this folder. Please cd to the directory with the desired HNAS diagnostics.\n";
       exit;
    } elsif ($diagfsrnum == 1){
       $zipped_diag = @diagfsr[0];
       print "The following file was found:\n$zipped_diag\nIs this the file you would like to analyze? Y/N\n";
       chomp(my $useryn = <STDIN>);
       if ($useryn =~ /^n/i || $useryn =~ /^no/i ){
          print "Please cd into the directory that holds the file you'd like to analyze and try again.\n";
          exit;
       }
    } else {
       my $count = 0;
       print "The following files were found.\n";
       foreach my $diagnostic(@diagfsr){
          print "[$count]: $diagnostic\n";
          $count++;
       }
       print "Please choose the index number corresponding to the file you wish to analyze\n";
       chomp(my $diagfindex = <STDIN>);
       $zipped_diag = @diagfsr[$diagfindex];
    }
}







#Unzip Parent diagnositc and child SMU diagnostic
sub unzip_diag{
    #Unzip the new diagnostic into its own folder
    my $unzipped_diag = "$1" if ($zipped_diag =~/(^Diagnostics.*)(\.zip)/);
    unzip($zipped_diag,$unzipped_diag);

    #Open and read unzipped diagnostic to identify SMUDiagnostics.zip
    opendir my $smu_dh, "$unzipped_diag" or die "$!";
    foreach my $file (readdir $smu_dh){
        $z_smu_diag = $file if $file =~/SMUDiagnostics.zip/i;
    }
    my $uz_smu_diag = "$1" if ($z_smu_diag =~/(SMU.*)\.zip/);
    chdir $unzipped_diag;
    unzip($z_smu_diag, $uz_smu_diag);
    
}






#A rewritten unzip function found on github used in the unzip diag sub
sub unzip {
    my ($file, $dest) = @_;
 
    die 'Need a file argument' unless defined $file;
    $dest = "." unless defined $dest;
 
    my $u = IO::Uncompress::Unzip->new($file)
        or die "Cannot open $file: $UnzipError";
 
    my $status;
    for ($status = 1; $status > 0; $status = $u->nextStream()) {
        my $header = $u->getHeaderInfo();
        my (undef, $path, $name) = splitpath($header->{Name});
        my $destdir = "$dest/$path";
 
        unless (-d $destdir) {
            mkpath($destdir) or die "Couldn't mkdir $destdir: $!";
        }
 
        if ($name =~ m!/$!) {
            last if $status < 0;
            next;
        }
 
        my $destfile = "$dest/$path/$name";
        my $buff;
        my $fh = IO::File->new($destfile, "w")
            or die "Couldn't write to $destfile: $!";
        while (($status = $u->read($buff)) > 0) {
            $fh->write($buff);
        }
        $fh->close();
        my $stored_time = $header->{'Time'};
        utime ($stored_time, $stored_time, $destfile)
            or die "Couldn't touch $destfile: $!";
    }
 
    die "Error processing $file: $!\n"
        if $status < 0 ;
 
    return;
}