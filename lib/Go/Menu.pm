package Go::Menu;
$VERSION = v0.0.1;

use strict;
use warnings;
use Go::File;
use Go::Device;
use Go::Term;
use Go::Update;

# printCertificateWizard()

sub printCertificateWizard {
    print `clear`;
    printMenuBar();
    printMenuLogo();
    printMenuHeader("Setup Instructions");
    printWithColor("Let's create your certificates.\n", "yellow");
    printWithColor("Do you want to protect your private key with a password?","white");
    printWithColor(" (y/n)\n", "green");
    printWithColor("(Enter the password everytime you decrypt, but more secure)\n", "darkgray");
    
    my $confirmInput = <STDIN>;
    while($confirmInput!~m/^[y,n]/){
        printWithColor("Invalid input: $confirmInput\n","red");
        printWithColor("(y/n) ", "white");
        $confirmInput=<STDIN>;
    }
    chomp($confirmInput);

    if ($confirmInput eq "y") {
        Go::Config::writeConfig("passwordProtectPrivateKey","yes");
    } else {
        Go::Config::writeConfig("passwordProtectPrivateKey","no");
    }

    printWithColor("Press \e[7;32mEnter\e[0;39m to create your private/public key.", "white");
    <STDIN>;
    my $privateKeyLocation = Go::File::createPrivateKey();
    printWithColor("Private key generated: $privateKeyLocation\n","green");
    printWithColor("Creating a public key...\n", "white");
    my $publicKeyLocation = Go::File::createPublicKey();
    printWithColor("Public key generated: $publicKeyLocation\n\n","green");
    
}

# printMainMenu()
#
# Prints the default menu (if you just run 'go')
sub printMainMenu {
    print `clear`;
    printMainMenuHeader();
    
    printMenuOption(1, "Add a device");
    printMenuOption(2, "Delete a device");
    printMenuOption(3, "List all devices");
    
    my $selection = getSelectionInput();

    if ($selection == 1) { 
        printAddDeviceMenu(); 

    } elsif ($selection == 2){
        printDeleteDeviceMenu();

    } elsif ($selection == 3) {
        printDeviceList();

    };
}

sub printMainMenuHeader {
    my @deviceList = Go::File::getDevices([]);
    
    printMenuBar();
    printMenuLogo();
    
    if (scalar(@deviceList) == 0){

        printMenuHeader("Setup Instructions");
        printWithColor("You need to add a device. Enter \e[7;32m1\n", "yellow");
        
    } else {

        printWithColor("Use: type '","darkgray");
        printWithColor("go <searchTerm>","white");
        printWithColor("'.\n", "darkgray");
        printWithColor("Supports ∞ search terms. ^c to exit.\n", "darkgray");
    }

    printMenuBar(); 
}

sub printDeviceList {
    my @deviceList = Go::File::getDevices([]);

    printDeviceSelectionMenu(\@deviceList);
    my $selectedDevice = $deviceList[getSelectionInput() - 1];
    my %device = Go::Device::getDeviceInfo($selectedDevice);
    Go::Device::connectToDevice(\%device);
}

sub printDeleteDeviceMenu {
    my @deviceList = Go::File::getDevices([]);

    printDeviceSelectionMenu(\@deviceList);
    my $deviceLineToDelete = $deviceList[getSelectionInput() - 1];
    my %deviceToDelete = Go::Device::getDeviceInfo($deviceLineToDelete);
    Go::File::deleteDevice($deviceToDelete{'name'});
    printWithColor("Device ", "white");
    printWithColor("$deviceToDelete{'name'} ", "green");
    printWithColor("@ $deviceToDelete{'ip'}", "darkgray");
    printWithColor(" deleted.\n", "white");
    printMainMenu();
}

# printDeviceSelectionMenu(@devices);
#
# prints a selection menu from an array of devices

sub printDeviceSelectionMenu {
    my $devicesToPrintRef = shift;
    my @devicesToPrint = @{$devicesToPrintRef};
    my $numberOfDevices = scalar(@devicesToPrint);

    print `clear`;
    if ($numberOfDevices <= 0) {
        printMenuBar();
        printWithColor("You need to add a device!\n", "red");
        printMainMenu();
    } else {
        my $count = 0;
        printMenuHeader("Select a device");
        foreach my $deviceLine (@devicesToPrint) {
            $count++;
            my %deviceInfo = Go::Device::getDeviceInfo($deviceLine);
            printWithColor(" $count. ","darkgray");
            printWithColor("$deviceInfo{'name'} ", "green");
            printWithColor("\@ ","darkgray");
            printWithColor("$deviceInfo{'ip'} \n","lightgray");
            # print (" $count - $deviceInfo{'name'} - $deviceInfo{'ip'} \n");
        }
        printMenuBar();
    }
}

sub printAddDeviceMenu {
    my %deviceToAdd;

    printMenuHeader("Add a device");

    my $deviceStringRegex = qr/^[\w,\-]+$/;
    $deviceToAdd{'name'} = getValidatedInput("Device name", $deviceStringRegex);

    my $deviceIpRegex = qr/^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/;
    $deviceToAdd{'ip'} = getValidatedInput("Device IP", $deviceIpRegex);

    $deviceToAdd{'username'} = getValidatedInput("Device username", $deviceStringRegex);

    

    printWithColor("Please select ","white");
    printWithColor("1", "green"); 
    printWithColor(" for password, ","white");
    printWithColor("2", "green");
    printWithColor(" for an existing SSH key.\n","white");

    my $authModeRegex = qr/^[1,2]/;
    $deviceToAdd{'authMode'} = getValidatedInput("Device Auth Mode",$authModeRegex);

    if ($deviceToAdd{'authMode'} == 1){
        system "stty -echo";
        print "Password: ";
        chomp(my $passwordInput = <STDIN>);
        print "\n";
        system "stty echo";
        $deviceToAdd{'passwordId'} = Go::File::createPassword($passwordInput);
    } else {
        $deviceToAdd{'passwordId'} = 0;
    }
    

    # TODO: Break into fnuction to print devices
    printWithColor("Please confirm the device settings:\n","white");
    Go::Device::printDeviceDetails(\%deviceToAdd);

    # TODO: Break into confirm function
    printWithColor("Is this information correct? (", "white");
    printWithColor("y", "green");
    printWithColor("/", "white");
    printWithColor("n", "green");
    printWithColor("): ", "white");

    my $confirmInput = <STDIN>;
    while($confirmInput!~m/^[y,n]/){
        printWithColor("Invalid input. (y/n)\n","red");
        printWithColor("(y/n) ", "white");
        $confirmInput=<STDIN>;
    }
    chomp($confirmInput);
    
    if (Go::File::createDevice(\%deviceToAdd)) {
        printWithColor("Device Added! Hit enter to continue.", "green");
        <STDIN>;
    } else {
        printWithColor("Failed to add device! Hit enter to continue.", "red");
        <STDIN>;        
    }
    
    printMainMenu();
    exit;
}

sub printMenuHeader {
    my $title = shift;
    my $titleLength = length $title;
    my $titleDecorationLength = 4;
    $titleLength += $titleDecorationLength;

    my @terminalSize = getTerminalSize();
    my $barLength = ($terminalSize[1] / 2) - ($titleLength / 2);

    my $char = 1;
    while ($char <= $barLength) {
        $char++;
        printWithColor("-","darkgray");
    }

    printWithColor("[ ", "darkgray");
    printWithColor($title,"cyan");
    printWithColor(" ]", "darkgray");

    $char += $titleLength;
    while ($char <= $terminalSize[1]) {
        $char++;
        printWithColor("-","darkgray");
    }
    print "\n";
}

sub printMenuBar {
    my @terminalSize = getTerminalSize();
    my $char = 1;
    while ($char <= $terminalSize[1]) {
        $char++;
        printWithColor("-","darkgray");
    }
    print "\n";
}

sub printMenuOption {
    my $optionNumber = shift;
    my $optionText = shift;
    printWithColor(" $optionNumber. ","darkgray");
    printWithColor("$optionText\n", "green");
}

sub printMenuLogo {
    my @terminalSize = getTerminalSize();
    my $terminalWidth = $terminalSize[1];

    my $version = Go::Update::getVersion();
    printfWithColor($terminalWidth, "v $version", "darkgray");

    print "\n";

    my $centerLine = int($terminalWidth / 2) + 7;

    printfWithColor($centerLine, ",---. ,---.\n", "green"); 
    printfWithColor($centerLine, "|   | |   |\n", "yellow");    
    printfWithColor($centerLine, "`---| `---'\n", "blue");  
    printfWithColor($centerLine, "`---'      \n","lightred");    
    print "\n";
}

# getSelectionInput();
#
# Returns:
# $input - the number seletion of a device

sub getSelectionInput {
    print "Selection: ";
    my $input=<STDIN>;
    if($input!~m/^\d+$/){
        printWithColor("Invalid selection.\n","red");
        exit;
    }
    return $input;
}


sub getValidatedInput {
    my $inputLabel = shift;
    my $validRegex = shift;

    printWithColor("$inputLabel: ", "white");
    my $input=<STDIN>;
    while($input!~ $validRegex){
        printWithColor("Invalid $inputLabel.\n","red");
        printWithColor("$inputLabel: ", "white");
        $input=<STDIN>;
    }
    chomp($input);
    return $input;
}

sub getTerminalSize {
    my $sttySizeOutput = `stty size`;
    my @terminalSize;
    if ($sttySizeOutput =~ m/(\d+)\ (\d+)/){
        $terminalSize[0] = $1;
        $terminalSize[1] = $2;
    }
    return @terminalSize;
}