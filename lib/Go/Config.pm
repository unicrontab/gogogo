package Go::Config;
$VERSION = v0.0.1;

use strict;
use warnings;
use Go::File;

my $configFileLocation = ("./goConfig.list");

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
