package Go::Device;
$VERSION = v0.0.1;

use strict;
use warnings;

# Use Expect to interact with the ssh session
use Expect;
$Expect::Log_Stdout = 0;
use Go::Term;
use Go::File;

# printDeviceDetails(%device)
#
# Prints the full details of a device
sub printDeviceDetails {
    my %device = %{$_[0]};
    printWithColor("Device Name: ", "darkgray");
    printWithColor("$device{'name'}\n", "green");
    printWithColor("Device ip: ", "darkgray");
    printWithColor("$device{'ip'}\n", "green");
    printWithColor("Device username: ", "darkgray");
    printWithColor("$device{'username'}\n", "green");
    printWithColor("Device auth mode is: ", "darkgray");
    if ($device{'authMode'} == 1){
        printWithColor("password\n", "green");
        printWithColor("Device password id: ", "darkgray");
        printWithColor("$device{'passwordId'}\n", "green");
    } elsif ($device{'authMode'} == 2) {
        printWithColor("SSH Key\n", "green");
    }
}

# getFilteredDeviceList(@deviceList, @searchTermList);
#
# Returns:
# @filteredDevices - an array of devices filtered by the search term list
sub getFilteredDeviceList {
    my $deviceListRef = shift;
    my @deviceList = @{$deviceListRef};

    my $searchTermListRef = shift;
    my @searchTermList = @{$searchTermListRef};

    my @filteredDevices;
    foreach my $deviceLine (@deviceList) {
        if ($deviceLine=~m/(\S+\|\d+\.\d+\.\d+\.\d+)?/){
            my $deviceStringToMatch = $1;

            my $match = 0;
            foreach my $term(@searchTermList) {
                if ($deviceStringToMatch=~m/$term/i) {
                    $match++;
                }
            }
            if ($match == scalar(@searchTermList)) {
                push(@filteredDevices,$deviceLine)
            }
        } else {
            error("Line in device list has formatting error: '$deviceLine'");
        }
    }

    return @filteredDevices;
}

# getDeviceInfo($deviceString);
#
# Returns:
# %device
sub getDeviceInfo {
    my $deviceLine = shift;
    my %deviceToReturn;

    if ($deviceLine=~m/(\S+)\|(\d+\.\d+\.\d+\.\d+)\|(\S+)\|(\d+)\|(\S+)/){
        $deviceToReturn{'name'} = $1;
        $deviceToReturn{'ip'} = $2;
        $deviceToReturn{'username'} = $3;
        $deviceToReturn{'passwordId'} = $4;
        $deviceToReturn{'authMode'} = $5;
        return %deviceToReturn;
    } else {
        error("Line in device list has formatting error: '$deviceLine'");
    }
}

# connectToDevice(%device);
#
# Connects to a device 
sub connectToDevice {
    my %deviceToConnectTo = %{$_[0]};

    my $deviceName = $deviceToConnectTo{'name'};
    my $deviceIp = $deviceToConnectTo{'ip'};
    my $deviceUsername = $deviceToConnectTo{'username'};
    my $authMode = $deviceToConnectTo{'authMode'};
    my $password;
    if ($authMode == 1) {
        $password = Go::File::getPasswordById($deviceToConnectTo{'passwordId'});
    }

    printWithColor("Connecting to $deviceName at $deviceIp   ","darkgray");
    printConnectionStatus("red");


    my $temp;
    my $response;
    my $sshCommand = "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $deviceUsername\@$deviceIp";

    my $session = Expect->spawn($sshCommand) or die "Couldn't ssh to $deviceName\n";
    #Catch winch signal
    $session->slave->clone_winsize_from(\*STDIN);
    $SIG{WINCH} = \&winch;

    sub winch {
        $session->slave->clone_winsize_from(\*STDIN);
        kill WINCH => $session->pid if $session->pid;
        $SIG{WINCH} = \&winch;
    }

    printConnectionStatus("yellow");

    if ($authMode == 1) {
        printConnectionStatus("yellow");
        $response = $session->expect(10,"assword:");
        if ($response){
            if ($response == 1) {
                printConnectionStatus("yellow");
                $temp=$session->exp_before();
                printConnectionStatus("yellow");
                $session->send("$password\r");
            } 
        } else {
            printConnectionStatus("red");
        }
    } elsif ($authMode == 2) {
        printConnectionStatus("yellow");
    }


    #match using regex, starting on the 3rd argument
    $response = $session->expect(10,'-re',"assword:","\#","\>","\$","Network is unreachable","Permission denied");
    $temp=$session->exp_before();

    if ($response){
        if ($response == 1) {
            printConnectionStatus("red");
            error("\nBad Password.\n");
            exit;
        } elsif ($response >= 2 && $response <=4) {
            printConnectionStatus("green");
        } elsif ($response == 5) {
            printConnectionStatus("red");
            error("\nNetwork Unreachable.\n");
            exit;
        } elsif ($response == 6) {
            printConnectionStatus("red");
            error("\nYour SSH Key was denied.\n");
            exit;
        } 
        print "\n";

        $session->send("\r");
        $session->interact;
    } else {
        printConnectionStatus("red");
        error("\nConnection timeout when connecting to $deviceName @ $deviceIp\n");
    } 
}

# printConnectionStatus($status)
#
# Will erase and reprint the status based on $status  
sub printConnectionStatus {
    my $status = shift;
    my %statusOutput;
    $statusOutput{'green'} = ":)";
    $statusOutput{'yellow'} = ":|";
    $statusOutput{'red'} = ":(";
    printWithColor("\b\b" . $statusOutput{$status}, $status);
}

1; # Last line is required to eval true. Yay Perl.