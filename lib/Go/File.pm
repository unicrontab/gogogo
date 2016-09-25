package Go::File;
$VERSION = v0.0.1;

use strict;
use warnings;
use Go::Device;
use Go::Config;
use Go::Term;
use Cwd qw(abs_path);
my $currentFile = abs_path($0);
my $mainDir;
if ($currentFile =~ m/^(\S+)\/go\.pl/){
    $mainDir = $1;
};

my %config =  Go::Config::getConfig();

my $userDataLocation = "$mainDir/$config{'userDataLocation'}";
my $deviceDataLocation = "$userDataLocation/$config{'deviceDataLocation'}";

my $passwordFileLocation = "$userDataLocation/$config{'passwordFileLocation'}";
my $deviceFileLocation = "$userDataLocation/$config{'deviceFileLocation'}";
my $privateKeyLocation = "$userDataLocation/$config{'privateKeyLocation'}";
my $publicKeyLocation = "$userDataLocation/$config{'publicKeyLocation'}";
my $privateKeySize = "$config{'privateKeySize'}";

# getFileData($fileLocation);
#
# Returns:
# @fileContents 

sub getFileData {
    my $fileLocation = shift;

    if (! -e $fileLocation) {
        `touch $fileLocation`;
    } 
    open(FILE, "<$fileLocation");
        my @fileContents = <FILE>;
        my @cleanedContents = removeEmptyLines(\@fileContents);
    close(FILE);

    return  @cleanedContents;
}

# removeEmptyLines(@dirtyArray)
#
# Returns:
# @cleanArray - Array with no lines that are empty
sub removeEmptyLines {
    my $dirtyArrayRef = shift;
    my @dirtyArray = @{$dirtyArrayRef};

    my @cleanArray;
    foreach my $line(@dirtyArray) {
        if ($line !~ m/^\s*$/) {
            push(@cleanArray,$line);
        }
    }

    return @cleanArray;
}

# getDevices()
#
# Returns:
# @devices - devices from device file that match search terms 
sub getDevices {
    my $searchTermRef = shift;
    my @searchTerms = @{$searchTermRef};
    my @deviceData = getFileData($deviceFileLocation);

    return Go::Device::getFilteredDeviceList(\@deviceData, \@searchTerms);
}


# createDevice()
# 
# Returns:
# 1 - (true)
sub createDevice {
    my $deviceRef = shift;
    my %device = %{$deviceRef};

    open(FILE, ">>", $deviceFileLocation) or die "Could not open file '$deviceFileLocation' $!";
    print FILE "$device{'name'}|";
    print FILE "$device{'ip'}|";
    print FILE "$device{'username'}|";
    print FILE "$device{'passwordId'}|";
    print FILE "$device{'authMode'}\n";
    close FILE;

    return 1;
}

# deleteDevice($deviceName);
# 
# Deletes a devices based on the the passed in string (preferable name)
sub deleteDevice {
    my $deviceName = shift;

    # Read in the file
    open(FILE, "<", $deviceFileLocation) or die "Could not open file '$deviceFileLocation' $!";
    my @fileContents = <FILE>;
    close FILE;

    # Write all devices back except the one to be deleted
    open(FILE, ">", $deviceFileLocation) or die "Could not open file '$deviceFileLocation' $!";
    foreach my $line (@fileContents) {
        if ($line !~ m/$deviceName/) {
            print FILE $line;
        }
    }
    close FILE;
}

# getPasswordById($id)
#
# Returns: 
# $password - the device password
sub getPasswordById {
    my $passwordId = shift;
    my $passStr=`cat $passwordFileLocation | egrep '^$passwordId'`;
    if ($passStr=~m/(\d+)\|(\S+)?/){
        return decryptPassword($2);
    } else {
        error("Formatting on file: $passwordFileLocation at line $passwordId");
    }
}

# createPassword($password)
# 
# Retruns:
# $passwordId - writes the password to the password file and returns .dat password file location 
sub createPassword {
    my $password = shift;
    chomp($password);
    my @passwordFileContents = Go::File::getFileData($passwordFileLocation);

    my $largestId = 0;
    foreach my $passwordLine (@passwordFileContents) {
        if ($passwordLine =~ m/^(\d+)\|(\S+)/) {
            if ($1 > $largestId) {
                $largestId = $1;
            }
        }
    }

    my $newPasswordId = $largestId + 1;
    my $passwordDataLocation = encryptPassword($password, $newPasswordId);

    if ($passwordDataLocation) {
        open(FILE, ">>", $passwordFileLocation) or die "Could not open file '$passwordFileLocation' $!";
        print FILE "$newPasswordId|";
        print FILE "$passwordDataLocation\n";
        close FILE;
        return $newPasswordId;
    } else {
        error("Failed to create $newPasswordId.dat\n");
        exit;
    }
    
}

# encryptPassword($password,$passwordId)
# 
# Returns:
# $fileLocation - location of encrypted password
sub encryptPassword {
    my $password = shift;
    my $passwordId = shift;
    if (! -e "$deviceDataLocation/") {
        `mkdir $deviceDataLocation`;
    }

    `echo "$password" | openssl rsautl -encrypt -inkey $publicKeyLocation -pubin -out $deviceDataLocation/$passwordId.dat`;
    if (-e "$deviceDataLocation/$passwordId.dat") {
        printWithColor("Created $passwordId.dat\n", "green");
        return "$deviceDataLocation/$passwordId.dat";
    } else {
        return 0;
    }
}

# decryptPassword($encyptedFileLocation)
# 
# Returns:
# $password - returns the decrypted password
sub decryptPassword {
    my $encryptedFileLocation = shift;

    my $password;
    if (-e $encryptedFileLocation) {
        $password = `openssl rsautl -decrypt -inkey $privateKeyLocation -in $encryptedFileLocation`;
        return $password;
    } else {
        error("\nEncrypted file $encryptedFileLocation does not exist!\n");
        printWithColor("Try Deleting/Adding the device.\n","white");
        exit;
    }
}


# checkForPasswordId($id)
#
# Returns:
# @passwordIdStatus - Boolean 1(true) or 0(false)
sub checkForPasswordId {
    my $passwordId = shift;

    open(FILE, "<", $passwordFileLocation) or die "Could not open file '$passwordFileLocation' $!";
    my $passwordContents = <FILE>;
    close FILE;

    my $match = 0;
    foreach my $line ($passwordContents) {
        if ($line =~ m/^(\d+)\|(\S+)/) {
            if ($1 == $passwordId) {
                $match = 1;
            }
        }
    }

    return $match;
}

# checkForPrivateKey()
# 
# Returns:
# $privateKeyStatus - returns a 1(true) if a private key exists
sub checkForPrivateKey {
    return -e $privateKeyLocation;
}

# checkForPublicKey()
# 
# Returns:
# $publicKeyStatus - returns a 1(true) if a public key exists
sub checkForPublicKey {
    return -e $publicKeyLocation;
}


# createPrivateKey()
# 
# Returns:
# $privateKeyLocation - the file containing the private key
sub createPrivateKey {
    `openssl genrsa -out $privateKeyLocation $privateKeySize`;
    return $privateKeyLocation;
}

# createPublicKey()

# Returns:
# $publicKeyLocation - the file containing the public key
sub createPublicKey {
    `openssl rsa -in $privateKeyLocation -out $publicKeyLocation -outform PEM -pubout`;
    return $publicKeyLocation;
}

sub ensureDataDirectoriesExist {
    if (! -e $userDataLocation) {
        `mkdir -p $userDataLocation`;
    }
    if (! -e $deviceDataLocation) {
        `mkdir -p $deviceDataLocation`;
    }
}

