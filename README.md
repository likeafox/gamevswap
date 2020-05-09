# gamevswap
A utility to easily switch between versions of Steam games on Linux.

## About

gamevswap helps with the problem of managing multiple versions of software installations concurrently which do not naturally support it, such as Steam games. Over the most basic solution of copying and manually moving around installation directories, gamevswap offers the following upsides:

* Less user interaction once set up
* Less filesystem writes
* Prevent Steam from clobbering an old version when it tries to force an update
* Seamlessly preserve user modifications across versions

gamevswap is licensed under GPLv3, and currently supports Ubuntu, Debian Linux, and Linux Mint.

## Getting started

This short tutorial will use the Steam game _RimWorld_ for its examples.

Begin by making sure the required package, _unionfs-fuse_, is installed, with something like:

```
$ sudo apt-get install unionfs-fuse
```

Then, change to the directory where you want gamevswap to be installed, and all alternate game versions to be saved. gamevswap can run under the same user account you run Steam under, so you will typically want it somewhere in your `$HOME`.

```
$ git clone https://github.com/likeafox/gamevswap.git
```

Make sure gamevswap is executable, and then run gamevswap without arguments:

```
$ chmod u+x gamevswap.sh
$ ./gamevswap.sh
```

This will create a few important subdirectories, as well as print out usage information for your reference.

### Locate game directories

You now want to make sure gamevswap can find your game directories. For that, you'll need to know where the library is, yourself. Here's sure way to find it:

1. In your Steam library, right click on the game you want to work with (in our case RimWorld), and go to Properties.
2. Click on the Local Files tab.
3. Then click on "Browse Local Files...", and a file browser window will pop up into the game directory.
4. Navigate up one level. You are now in your library directory, which will contain all or several of your Steam games.

Now that you've found the library directory, create a symbolic link to it in gamevswap's `searchdirs/` directory. You can create the link with the file browser, or use the command line like so:

```
$ ln -s ~/.local/share/Steam/steamapps/common my-steam-library
```
### Separate any custom content

In preparation of creating the first game snapshot, if you have any custom user content in the game directory that you want to remain the same across all versions, you should remove it from the game directory to a temporary locgamevswap's dependency, , alled (non-Steam-workshop) mods are placed in `RimWorld/Mods/`. You should move them out, for now.

We'll later configure this custom content to be added to every version snapshot automatically.

### Create snapshots of game versions

Suppose you presently have RimWorld version 1.1 installed with Steam. To create a snapshot to switch to that version later you would run:

```
$ ./gamevswap.sh branch RimWorld 1.1
```

where "RimWorld" is the name of the directory in your game library that RimWorld is installed in. "1.1" is simply a user-defined tag you'll use to refer to that snapshot.

Repeat this process for each version you want to be swappable. 

To next make a snapshot of 1.0:

1. In your Steam library, right click RimWorld, and go to Properties.
2. Click on the Betas tab.
3. Select version 1.0 from the dropdown menu.
4. Confirm, and wait for RimWorld 1.0 to download and install.
5. Once it's done, run the same command as before, modified:

```
$ ./gamevswap.sh branch RimWorld 1.0
```

### Try it out!

With both snapshots created you can instantly switch between the two by using the mount command:

```bash
# switch to version 1.1
$ ./gamevswap.sh mount RimWorld 1.1
# switch back!
$ ./gamevswap.sh mount RimWorld 1.0
```

If Steam ever triggers an unwanted update, or deletes the install to install another version, you can always revert the changes by remounting:

```
$ ./gamevswap.sh unmount RimWorld
$ ./gamevswap.sh mount RimWorld
```

Omitting the version from the mount command as in the example above will select the most recently mounted version.

### Add your custom content

When the snapshots were created, they were stored in gamevswap's apps directory. Adding custom content to the game installation is as easy as placing it in `apps/{GAME}/user/` .

To re-add your manually-installed mods back into RimWorld, create `apps/RimWorld/user/Mods`, and then place all your mods into it.

Note: You'll need to remount RimWorld the first time you do this for this change to take effect. Changes will propagate automatically from then on.

### Auto-mounting on startup

You'll certainly want your game to be mounted automatically when you log into your computer, so you're encouraged to place a mount at the end of your user login script:

```
./gamevswap.sh mount RimWorld
```