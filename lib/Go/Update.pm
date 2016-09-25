package Go::Update;
$VERSION = v0.0.1;

use strict;
use warnings;
use Go::Term;
use Go::Menu;

# checkForUpdates
#
# checks git for updates to your current branch
sub checkForUpdates {
    `git fetch`;
    my $gitStatusOutput = `git status`;

    if ($gitStatusOutput =~ m/Your branch is behind/g) {
        printWithColor("Update available! Would you like to update? (y/n) ", "green");
        my $confirmInput = <STDIN>;
        while($confirmInput!~m/^[y,n]/){
            printWithColor("Invalid input. (y/n)\n","red");
            printWithColor("Update? (y/n) ", "green");
            $confirmInput=<STDIN>;
        }
        chomp($confirmInput);
        if ($confirmInput =~ m/^y$/){
            updateGo();
        }
        
    } elsif ($gitStatusOutput =~ m/Your branch is up-to-date/) {
        return 0;
    } elsif ($gitStatusOutput =~ m/Changes not staged for commit/) {
        error("Please commit or discard your local changes!\n");
        return 0;
    } else {
        error("Error in git status:\n $gitStatusOutput");
        return 0;
    }
}

sub updateGo {
    my $gitUpdateOutput = `git pull`;
    print $gitUpdateOutput;
}