package Go::Config;
$VERSION = v0.0.1;

use strict;
use warnings;
use Go::File;
use Cwd qw(abs_path);
my $currentFile = abs_path($0);
my $mainDirectory;
if ($currentFile =~ m/^(\S+)\/go\.pl/){
    $mainDirectory = $1;
};

my $configFileLocation = $mainDirectory . "/goConfig.list";

# getConfig()
#
# Returns: 
# %config
sub getConfig {
    my @configFileContents = Go::File::getFileData($configFileLocation);
    my %config;
    foreach my $line (@configFileContents) {
        if ($line =~ m/^(\S+)\|(\S+)/) {
            $config{$1} = $2;
        }
    }
    return %config;
}
