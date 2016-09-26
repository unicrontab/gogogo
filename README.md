## go
A terminal based ssh login manager/automator.

#### Getting Started with go:

To use go with just `go` you will need to symlink **go.pl** to **go** and put the symlink in a directory that exists in your $PATH environment variable.
`ln -s $PWD/go.pl /usr/local/bin/go`

Then you can just run `go` to get to the main menu. Follow the instructions from there.


#### Using go:

1. Fast Search and Connect: `go nginx prod`

	This will find a filtered list of devices that match 'nginx' and 'prod' and allow you to select which one you want to SSH into. If only 1 device matches, it will automatically log you in.

2. Add/Delete/List Devices: `go`

	This will bring you to the main menu to add, delete, or list devices.


#### Configure go:

The default configuration file is located at: `.goConfig.list`.

The file is formatted: \<key>|\<value>

The following are available to configure:

######**Changing directory locations might not work as expected :/**
* **passwordProtectPrivateKey** - Will make you enter a passphrase every time we decrypt a password (or access the private key)
* **userDataLocation** - directory name containing all of the data files
* **deviceDataLocation** - directory name containing all the encrypted password files
* **passwordFileLocation** - the filename of the password reference file
* **deviceFileLocation** - the filename of the device list
* **privateKeyLocation** - the filename of the private key
* **publicKeyLocation** - the filename of the public key
* **privateKeySize** - the key size of the private key
* **checkForUpdates** - (yes/no) if yes, will check for updates every time `go` is run without search terms (not when fast search/connecting)

###### Default Config:
```
passwordProtectPrivateKey|no
userDataLocation|userData
deviceDataLocation|deviceData
passwordFileLocation|.goPass
deviceFileLocation|goDevices.list
privateKeyLocation|private.pem
publicKeyLocation|public.pem
privateKeySize|4096
checkForUpdates|yes
```