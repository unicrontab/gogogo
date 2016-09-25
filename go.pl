#!/usr/bin/perl
use strict;
use warnings;

use lib "./lib";
use Go::Menu;
use Go::File;
use Go::Term;
use Go::Device;
use Go::Update;

# check for updates
Go::Update::checkForUpdates();

# check if the config directories exist, create them if they don't
Go::File::ensureDataDirectoriesExist();

if (! Go::File::checkForPrivateKey()) {
	Go::Menu::printCertificateWizard();
}

my $numberOfSearchTerms = scalar @ARGV;
my @initiallyMatchedDevices = Go::File::getDevices(\@ARGV);
my $numberOfMatchedDevices = scalar @initiallyMatchedDevices;

# just type 'go'
if ($numberOfSearchTerms == 0) {
	Go::Menu::printMainMenu();

# search terms match *ONE* device
} elsif ($numberOfMatchedDevices == 1) {
	my %device = Go::Device::getDeviceInfo($initiallyMatchedDevices[0]);
	Go::Device::connectToDevice(\%device);

# search terms match *MULTIPLE* devices
} elsif ($numberOfMatchedDevices > 1) {
	Go::Menu::printDeviceSelectionMenu(\@initiallyMatchedDevices);
	my $deviceSelection = Go::Menu::getSelectionInput() - 1;
	my %device = Go::Device::getDeviceInfo($initiallyMatchedDevices[$deviceSelection]);
	Go::Device::connectToDevice(\%device);

# search terms match *ZERO* devices
} elsif ($numberOfMatchedDevices == 0) {
	error("No match. Use 'go' to add devices.\n");
} 

exit;
