package Go::Menu;
$VERSION = v0.0.1;

use strict;
use warnings;
use Go::File;
use Go::Device;
use Go::Term;
use Go::Update;


# printSetupWizard()
#
# Prints the SetupWizard
sub printSetupWizard {
    print `clear`;
    printMenuBar();
    printMenuLogo();

    printSetupWizardIntro();
    printCertificateWizard();
    printUpdateWizard();

    print `clear`;
}

# printSetupWizardIntro()
#
# prints the intro text for the SetupWizard
sub printSetupWizardIntro {
    printMenuHeader("Setup Wizard");
    printWithColor("Welcome. You are at the go setup wizard. After go is configured, you will most likely only use go with search terms.\n\n", "darkgray");
    printWithColor("To directly connect to a device, match only 1 by using specific terms:\n", "darkgray");
    printWithColor("go 10.100 dev api\n\n", "white");
    printWithColor("To print a filtered list of devices/ip's either list devices through the menu ('go'), or match multiple devices with search terms:\n", "darkgray");
    printWithColor("go dev \n\n", "white");
    printWithColor("Press ", "white");
    printWithColor("Enter ", "green");
    printWithColor("to set up go!","white");
    <STDIN>;
}

# printCertificateWizard()
#
#
sub printCertificateWizard {
    printMenuHeader("Certificates");
    printWithColor("Do you want to password protect your private key? Default 'n'.\n","white");
    printWithColor("(Enter this password everytime you connect if 'y')\n", "darkgray");
    printWithColor("(y/n) ", "green");
    
    my $choice = confirmChoice();
    if ($choice eq "y") {
        Go::Config::writeConfig("passwordProtectPrivateKey","yes");
    } else {
        Go::Config::writeConfig("passwordProtectPrivateKey","no");
    }

    printWithColor("Press ", "white");
    printWithColor("Enter ","green"); 
    printWithColor("to create your private/public key ", "white");
    <STDIN>;

    my $privateKeyLocation = Go::File::createPrivateKey();
    printWithColor("Private key generated: $privateKeyLocation\n","green");
    printWithColor("Creating public key...\n", "white");
    my $publicKeyLocation = Go::File::createPublicKey();
    printWithColor("Public key generated: $publicKeyLocation\n\n","green");
}

# print
#
#
sub printUpdateWizard {
    printMenuHeader("Updates");
    printWithColor("Would you like to automatically check for updates?\n", "white");
    printWithColor("Update check only occurs at the menu, not when search/connecting", "darkgray");
    printWithColor("\n(y/n) ", "green");

    my $choice = confirmChoice();
    if ($choice eq "y") {
        Go::Config::writeConfig("checkForUpdates","yes");
    } else {
        Go::Config::writeConfig("checkForUpdates","no");
    }

    printWithColor("What update branch would you like receive updates from?\n", "white");
    printMenuOption(1, "master - Stable");
    printMenuOption(2, "develop - new features / unstable");

    my $menuSelectionRegex = qr/^[1-2]$/;
    my $selection = getValidatedInput("Selection", $menuSelectionRegex);
    if ($selection == 1) { 
        Go::Update::switchBranch("master");
    } elsif ($selection == 2){
        Go::Update::switchBranch("develop");
        error("Branch change requires restart of go.\n");
    }

}

# printMainMenu()
#
# Prints the default menu (if you just run 'go')
sub printMainMenu {
    printMainMenuHeader();

    printMenuOption(1, "Add a device");
    printMenuOption(2, "Delete a device");
    printMenuOption(3, "List all devices");
    printMenuOption(4, "Configure updates");
    
    my $menuSelectionRegex = qr/^[1-4]$/;
    my $selection = getValidatedInput("Selection", $menuSelectionRegex);

    if ($selection == 1) { 
        printAddDeviceMenu(); 

    } elsif ($selection == 2){
        printDeleteDeviceMenu();

    } elsif ($selection == 3) {
        my @allDevices = Go::File::getDevices([]);
        my %device = printDeviceSelectionMenu(\@allDevices);

        Go::Device::connectToDevice(\%device);

    } elsif ($selection == 4) {
        printUpdateWizard();
        print `clear`;

        printMainMenu();
    }
}

# printMainMenuHeader()
sub printMainMenuHeader {
    printMenuBar();

    printVersionInfo();
    printMenuLogo();
    printMainMenuHeaderHelperText();

    printMenuBar(); 
}

# printMainMenuHeaderHelperText()
sub printMainMenuHeaderHelperText {
    my @deviceList = Go::File::getDevices([]);
    if (scalar(@deviceList) == 0){
        printMenuHeader("Devices");
        printWithColor("You need to add a device. Enter ", "white");
        printWithColor("1\n", "green");
        
    } else {
        printWithColor("Use: type '","darkgray");
        printWithColor("go <searchTerm>","white");
        printWithColor("'.\n", "darkgray");
        printWithColor("Supports ∞ search terms. ^c to exit.\n", "darkgray");
    }
}

# printMenuLogo()
sub printMenuLogo {
    my @terminalSize = getTerminalSize();
    my $terminalWidth = $terminalSize[1];
    my $centerLine = int($terminalWidth / 2) + 7;

    printfWithColor($centerLine, ",---. ,---.\n", "green"); 
    printfWithColor($centerLine, "|   | |   |\n", "yellow");    
    printfWithColor($centerLine, "`---| `---'\n", "blue");  
    printfWithColor($centerLine, "`---'      \n", "lightred");    

    print "\n";
}

# printVersionInfo()
sub printVersionInfo {
    my @terminalSize = getTerminalSize();
    my $terminalWidth = $terminalSize[1];
    my $version = Go::Update::getVersion();
    my $branch = Go::Update::getBranch();
    printfWithColor($terminalWidth, "v $version ($branch)", "darkgray");
    print "\n";
}

# printDeleteDeviceMenu()
sub printDeleteDeviceMenu {
    my @deviceList = Go::File::getDevices([]);
    my %deviceToDelete = printDeviceSelectionMenu(\@deviceList);

    Go::File::deleteDevice($deviceToDelete{'name'});

    printWithColor("Device ", "white");
    printWithColor("$deviceToDelete{'name'} ", "green");
    printWithColor("@ $deviceToDelete{'ip'}", "darkgray");
    printWithColor(" deleted.\n", "white");

    printMainMenu();
}

# printDeviceSelectionMenu(@devices);
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
        }
        printMenuBar();
    }

    my $deviceListLength = $numberOfDevices + 1;
    my $deviceSelectionRegex = qr/^[1-$deviceListLength]$/;
    my $selectedDevice = $devicesToPrint[getValidatedInput("Selection", $deviceSelectionRegex) - 1];
    my %device = Go::Device::getDeviceInfo($selectedDevice);

    return %device;
}

# printPasswordInput()
# 
# Returns:
# $password
sub printPasswordInput {
    my @passwords = getPasswordInput();
    while ($passwords[0] ne $passwords[1]) {
        printWithColor("Passwords did not match.\n", "red");
        @passwords = getPasswordInput();   
    }
    return $passwords[0];
}

# getPasswordInput
# 
# Returns:
# $passwords - array with the two input passwords
sub getPasswordInput {
    my @passwords = ( "password", "badPassword" );

    print "Password: ";

    system "stty -echo";
    chomp($passwords[0] = <STDIN>);
    print "\nVerify Password: ";
    chomp($passwords[1] = <STDIN>);
    system "stty echo";

    print "\n";

    return @passwords;
}

# printAddDeviceMenu()
sub printAddDeviceMenu {
    my %deviceToAdd;

    printMenuHeader("Add a device");

    my $deviceStringRegex = qr/^[\w,\-]+$/;
    $deviceToAdd{'name'} = getValidatedInput("Device label", $deviceStringRegex);

    my $deviceIpRegex = qr/^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/;
    $deviceToAdd{'ip'} = getValidatedInput("Device IP", $deviceIpRegex);

    printAuthModeSelectionText();
    my $authModeRegex = qr/^[1,2]$/;
    $deviceToAdd{'authMode'} = getValidatedInput("Device Auth Mode", $authModeRegex);

    my $usernameStringRegex = qr/^[\S+]+$/;
    $deviceToAdd{'username'} = getValidatedInput("Device username", $usernameStringRegex);
    
    if ($deviceToAdd{'authMode'} == 1){
        my $password = printPasswordInput;
        $deviceToAdd{'passwordId'} = Go::File::createPassword($password);

    } elsif ($deviceToAdd{'authMode'} == 2) {
        $deviceToAdd{'passwordId'} = 0;
    }

    printWithColor("Please confirm the device settings:\n","white");
    Go::Device::printDeviceDetails(\%deviceToAdd);

    printWithColor("Is this information correct?\n","white");
    printWithColor("(y/n) ", "green");
    my $choice = confirmChoice();
    if ($choice eq "y"){
        if (Go::File::createDevice(\%deviceToAdd)) {
            printWithColor("Device Added! Hit enter to continue.", "green");
            <STDIN>;
        } else {
            error("Failed to add device! Hit enter to continue.", "red");
            <STDIN>;        
        }
    } elsif ($choice eq "n") {
        error("Did not create the device. Hit enter to continue.");
        <STDIN>
    }
    
    print `clear`;
    printMainMenu();
    exit;
}

# printAuthModeSelectionText()
sub printAuthModeSelectionText {
    printWithColor("Please select ","white");
    printWithColor("1", "green"); 
    printWithColor(" for password, ","white");
    printWithColor("2", "green");
    printWithColor(" for an existing SSH key.\n","white");
}

# printMenuHeader()
sub printMenuHeader {
    my $title = shift;
    my $titleLength = length $title;
    my $titleDecorationLength = 4;
    $titleLength += $titleDecorationLength;

    my @terminalSize = getTerminalSize();
    my $barLength = ($terminalSize[1] / 2) - ($titleLength / 2);

    printBar($barLength);
    printWithColor("[ ", "darkgray");
    printWithColor($title,"cyan");
    printWithColor(" ]", "darkgray");
    my $barLengthToEndOfLine = $terminalSize[1] - ($barLength + $titleLength);
    printBar($barLengthToEndOfLine);
    print "\n";
}

# printMenuBar()
sub printMenuBar {
    my @terminalSize = getTerminalSize();
    printBar($terminalSize[1]);
    print "\n";
}

# printBar($length)
sub printBar {
    my $length = shift;
    my $char = 1;
    while ($char <= $length) {
        $char++;
        printWithColor("-","darkgray");
    }
}

# printMenuOption()
sub printMenuOption {
    my $optionNumber = shift;
    my $optionText = shift;
    printWithColor(" $optionNumber. ","darkgray");
    printWithColor("$optionText\n", "green");
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

# getValidatedInput($inputLabel, $validRegex)
#
# Returns:
# $input - validated input
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

# confirmChoice()
# 
# Returns:
# $choice - 'y' or 'n'
sub confirmChoice {
    my $choice = <STDIN>;
    while($choice!~m/^[y,n]$/){
        printWithColor("Invalid input: $choice","red");
        printWithColor("(y/n) ", "green");
        $choice=<STDIN>;
    }
    chomp($choice);
    return $choice;
}
