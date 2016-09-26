package Go::Update;
$VERSION = v0.0.1;

use strict;
use warnings;
use Go::Term;
use Go::Menu;

use Cwd qw(abs_path);
my $currentFile = abs_path($0);
my $mainDirectory;
if ($currentFile =~ m/^(\S+)\/go\.pl/){
    $mainDirectory = $1;
};

my $gitArguments = "--git-dir=$mainDirectory/.git --work-tree=$mainDirectory";

# checkForUpdates
#
# checks git for updates to your current branch
sub checkForUpdates {
    my $fetchOutput = `git $gitArguments fetch 2>&1`;
    if ($fetchOutput =~ m/Could not resolve host: (\S+)/) {
        error("Could not resolve $1\n");
    }  else {


    my $gitStatusOutput = `git $gitArguments status`;

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
        } elsif ($gitStatusOutput =~ m/HEAD detached at (\S+)/) {
            error("You are not on a branch. You're on commit: $1 \n");
        } elsif ($gitStatusOutput =~ m/Changes not staged for commit/) {
            error("Please commit or discard your local changes!\n");
        } else {
            error("Error in git status:\n $gitStatusOutput");
        }
    }
}

sub updateGo {
    my $gitUpdateOutput = `git --git-dir=$mainDirectory/.git --work-tree=$mainDirectory pull`;
    print $gitUpdateOutput;
    error("You must restart go to apply the update.\n");
}

sub getVersion {
    my $version = `git $gitArguments describe`;
    chomp($version);
    return $version;
}