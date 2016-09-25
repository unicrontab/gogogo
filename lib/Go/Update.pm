package Go::Update;
$VERSION = v0.0.1;

use strict;
use warnings;
use Go::Term;

# checkForUpdates
#
# checks git for updates to the master branch
sub checkForUpdates {
    printWithColor("Checking for updates...\n", "white");
    my $gitStatusOutput = `git status`;
    if ($gitStatusOutput =~ m/Your branch is behind/) {
        printWithColor("Update available! Would you like to update?", "green");
        <STDIN>
    } elsif ($gitStatusOutput =~ m/Your branch is up-to-date/) {
        printWithColor("Go is up to date!\n", "white");
        return 0;
    } elsif ($gitStatusOutput =~ m/Changes not staged for commit/) {
        error("Please commit or discard your local changes!\n");
        return 0;
    } else {
        error("Error in git status:\n $gitStatusOutput");
        return 0;
    }

}