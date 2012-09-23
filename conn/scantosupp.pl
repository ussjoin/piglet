#!/usr/bin/perl

use strict;

my $device = shift;
my $outfile = shift;

use YAML::Syck;
use File::Spec::Functions qw(rel2abs);
use File::Basename;

my $knownnetworks = LoadFile(dirname(rel2abs($0))."/networks.yaml");

unless ($device && $outfile)
{
    print "Usage: scantosupp.pl <devicename> <output file>";
    exit(1);
}

open(FILE, ">$outfile");

my $networklist = `iwlist $device scan`;

my @networks = split(/Cell \d{2}/, $networklist); #This will give us cell 1 in @networks[1], as [0] will hold junk

delete $networks[0];

print FILE "ctrl_interface=DIR=/var/run/wpa_supplicant\n";

foreach (@networks)
{
    my $net = $_;
    my @data = split(/\n/, $net);
    my $bssid = $data[0];
    $bssid =~ /([A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2})/;
    $bssid = $1;
    
    my $ssid = $data[5];
    $ssid =~ /ESSID\:\"(.*)\"/;
    $ssid = $1;
    
    my $enc = $data[4];
    $enc = /Encryption key:(.+)/;
    $enc = $1;
   
 
	# TODO FIX: This doesn't actually grab full open networks, fix the logic here
	
	if ($knownnetworks->{$ssid}) # Don't bother with networks whose keys we don't know.
	{
	    print FILE "network={\n";
	    print FILE "ssid=\"$ssid\"\n";
	    print FILE "scan_ssid=1\n";
	    if ($enc eq "on")
	    {
	        # Also this is just a brutal hack. I can be a lot more precise-- specifying CCMP and the like-- but it doesn't matter, weirdly.
	        if ($net =~ /WPA/) #Because it doesn't seem to matter WPA/WPA2, which is concerning....
	        {
	            print FILE "key_mgmt=WPA-PSK\n";
	            print FILE "psk=\"$knownnetworks->{$ssid}\"\n";
	        }
	        else # Then it's WEP
	        {
	            #For WEP, we're going to assume KEY ID 0, because almost no one ever uses any other key index.
	            print FILE "key_mgmt=NONE\n";
				print FILE "wep_tx_keyidx=0\n";
                print FILE "wep_key0=$knownnetworks->{$ssid}\n";			
	        }
	    }
	    else
	    {
	        print FILE "key_mgmt=NONE\n";
	    }
    
	    print FILE "}\n\n";
	}
}


close(FILE);

