package Go::Term;
$VERSION = v0.0.1;

use strict;
use warnings;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(printWithColor printfWithColor getTerminalSize error);

# printWithColor($color);
sub printWithColor {
    my $stringToPrint = shift;
    my $colorChoice = shift;

    my %colors;
    $colors{'reset'} = "\e[1;39m";
    $colors{'red'} = "\e[1;31m";
    $colors{'green'} = "\e[1;32m";
    $colors{'yellow'} = "\e[1;33m";
    $colors{'blue'} = "\e[1;34m";
    $colors{'magenta'} = "\e[1;35m";
    $colors{'cyan'} = "\e[1;36m";
    $colors{'lightgray'} = "\e[1;37m";
    $colors{'darkgray'} = "\e[1;2m\e[1;39m";
    $colors{'lightred'} = "\e[1;91m";
    $colors{'lightgreen'} = "\e[1;92m";
    $colors{'lightyellow'} = "\e[1;93m";
    $colors{'lightblue'} = "\e[1;94m";
    $colors{'lightmagenta'} = "\e[1;95m";
    $colors{'lightcyan'} = "\e[1;96m";
    $colors{'white'} = "\e[1;97m";

    print "$colors{$colorChoice}$stringToPrint\e[m";

}

# printfWithColor
sub printfWithColor {
    my $width = shift;
    $width += 7;
    my $stringToPrint = shift;
    my $colorChoice = shift;

    my %colors;
    $colors{'reset'} = "\e[1;39m";
    $colors{'red'} = "\e[1;31m";
    $colors{'green'} = "\e[1;32m";
    $colors{'yellow'} = "\e[1;33m";
    $colors{'blue'} = "\e[1;34m";
    $colors{'magenta'} = "\e[1;35m";
    $colors{'cyan'} = "\e[1;36m";
    $colors{'lightgray'} = "\e[1;37m";
    $colors{'darkgray'} = "\e[1;39m"; #was before \e[1;2m
    $colors{'lightred'} = "\e[1;91m";
    $colors{'lightgreen'} = "\e[1;92m";
    $colors{'lightyellow'} = "\e[1;93m";
    $colors{'lightblue'} = "\e[1;94m";
    $colors{'lightmagenta'} = "\e[1;95m";
    $colors{'lightcyan'} = "\e[1;96m";
    $colors{'white'} = "\e[1;97m";

    printf("%$width"."s", "$colors{$colorChoice}$stringToPrint");

}

# error($errorMessage)
sub error {
    my $errorMessage = shift;
    printWithColor($errorMessage,"red");
}

# getTerminalSize
# 
# Returns:
# @terminalSize - [$height, $width]
sub getTerminalSize {
    my $sttySizeOutput = `stty size`;
    my @terminalSize;
    if ($sttySizeOutput =~ m/(\d+)\ (\d+)/){
        $terminalSize[0] = $1;
        $terminalSize[1] = $2;
    }
    return @terminalSize;
}
