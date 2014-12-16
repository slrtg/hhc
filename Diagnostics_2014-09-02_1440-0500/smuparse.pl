#!usr/bin/perl
use strict;
use warnings;
use IO::File;
use Cwd;
use IO::Uncompress::Unzip qw(unzip $UnzipError);
use File::Copy qw(copy);
use File::Path qw(mkpath);
use File::Spec::Functions qw(splitpath);

my $smu_version;
my $smu_hardware;

sub parse_smuinfo{
	open my $smuinfotxt, "smuinfo.txt" or die "Couldn't open file: $!";
	while (<$smuinfotxt>){
		#chomp;
		#print "$_";
		$smu_version = $2 if ($_ =~ /(System Management Unit \(SMU\) Version: )(\d+\.\d+\.\d+\.\d+)/);
		$smu_hardware = $_ if ($_ =~/Internal SMU|Virtual SMU|^SMU\d{3}$/);
	}
}

parse_smuinfo();
print "SMU Firmware: $smu_version\n";
print "SMU Hardware: $smu_hardware\n";