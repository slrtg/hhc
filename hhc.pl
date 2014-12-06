#!usr/bin/perl
use 5.016;
use IO::Uncompress::Unzip qw(unzip $UnzipError);
use File::Copy qw(copy);
use File::Remove qw(remove);


my $zipped_diag;
my @diagfsr;

#Open the CWD, find diagnostic files, and put them into Diagnostic Files Search Results (diagfsr)
opendir my $diagdir, "." or die "$!";

foreach my $file (readdir $diagdir){
	if($file =~ /^Diagnostics(.*)\.zip$/){
		push(@diagfsr, "$file");
	}

}

#Verifies how many diagnostic files were found and allows for user input on the results.
#Ultimately selects the HNAS zip that will be analyzed.

my $diagfsrnum = @diagfsr;
if ($diagfsrnum < 1){
	print "There are no diagnostic files in this folder. Please cd to the directory with the desired HNAS diagnostic.\n";
	exit;
} elsif ($diagfsrnum == 1){
	$zipped_diag = @diagfsr[0];
	print "The following diagnostic file was found:\n$zipped_diag\nIs this the file you would like to analyze? Y/N\n";
	chomp(my $useryn = <STDIN>);
	if ($useryn =~ /^n/i || $useryn =~ /^no/i ){
		print "Please cd into the directory that holds the diagnostic file you'd like to analyze and try again.\n";
		exit;
	}
} else {
	my $count = 0;
	print "The following diagnostic files were found.\n";
	foreach my $diagnostic(@diagfsr){
		print "[$count]: $diagnostic\n";
		$count++;
	}
	print "Please choose the index number corresponding to the file you wish to analyze\n";
	chomp(my $diagfindex = <STDIN>);
	$zipped_diag = @diagfsr[$diagfindex];
}

#Create a new CWD for unzipping the diagnostics and move the zip file to new directory

my $unzipped_diag = "$1$2" if ($zipped_diag =~/(^Diagnostics)(.*)(\.zip)/);
mkdir "$unzipped_diag";
copy ("$zipped_diag", "$unzipped_diag/$zipped_diag");
chdir ("$unzipped_diag") or die "$!";



#Unzip the relevant file and do stuff

my $diag_folder = new IO::Uncompress::Unzip $zipped_diag or die "Cannot open $zipped_diag: $UnzipError";
die "Zipfile has no members" if ! defined $diag_folder->getHeaderInfo;
for (my $status = 1; $status > 0; $status = $diag_folder->nextStream){
	my $name = $diag_folder->getHeaderInfo->{Name};
	warn "Processing member $name\n";
	unzip $zipped_diag => $name, Name => $name or die "unzip failed: $UnzipError\n";
}