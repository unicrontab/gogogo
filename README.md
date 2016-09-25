## go
A terminal based ssh login manager/automator.

####Getting Started with go:

After cloning, you will **(optionally)** need to symlink **go.pl** to **go** and put the symlink in a directory that exists in your $PATH environment variable.
`ln -s $PWD/go.pl /usr/local/bin/go`

Then you can just run `go`. Follow the instructions from there.


####Using go:

1. Fast Search and Connect: `go nginx prod`

	This will find any devices that match 'nginx' and 'prod' and allow you to select which one you want to SSH into. If only 1 device matches, it will automatically log you in.

2. Add/Delete/List Devices: `go`

	This will bring you to the main menu to add, delete, or list devices.


####Configure go;

The default configuration file is located at: `.goConfig.list`.

The file is formatted: \<key>|\<value>

The following are available to configure:

* userDataLocation - directory containing all of the data files
* deviceDataLocation - directory containing all the encrypted password files
* passwordFileLocation - the filename of the password reference file
* deviceFileLocation - the filename of the device list
* privateKeyLocation - the filename of the private key
* publicKeyLocation - the filename of the public key
* privateKeySize - the keysize of the private key