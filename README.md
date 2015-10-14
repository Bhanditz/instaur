# instaur
AUR helper for Arch Linux

## DISCLAIMER
Instaur is in early alpha testing stages and has a lot of upcoming changes. In my experience it works well, but it has only been tested on my devices. Instaur is unique in that it runs as root. An Instaur user is created during installation to execute the makepkg command without root privileges. This functionality is experimental and subject to change. It functions in this manner in order to create a user experience as similar to that of pacman as possible. Use at your own risk.

## Description

Instaur is a command line utility made for Arch Linux to install AUR packages. Instaur is intended to be used instead of a more automated AUR package installer such as Yaourt or Pacaur in order to put individualized package control back in the hands of the user while still automating the installation process. It only auto-installs dependencies that are found by pacman in the official repositories. Any package or dependency that is in AUR must be explicitly specified by the user in order for it to be installed. Prior to installing packages, Instaur notifies the user which dependencies may need to be updated manually.

## Usage

This documentation is no longer up to date with the latest features of Instaur. Most pacman options and operations should have some level of compatibility with Instaur. However, only the following are officially supported.

To install a single package using default settings, execute this command:<br />
```# instaur -S package-name```

Instaur can also install multiple packages in one command:<br />
```# instaur -S package-one package-two package-three```<br />
The packages will install in the order specified.

Instaur's options and operations can be placed anywhere in the command and apply to ALL packages being installed:<br />
### Operations
  * -S, -U<br />
      * These can be used but will both be ignored because Instaur already uses "pacman -U" by default to accomplish something analogous to -S.<br />
  * -R Uninstall<br />
      * Any parameter starting with -R will be passed in its entirely (everything until whitespace) to pacman, skipping all of Instaur.<br />
      * This is used to uninstall packages exactly as pacman would do it, except that it keeps Instaur.log up to date.<br />
      * For example, the following two commands have identical results.<br />
        * ```# instaur -Rs package-one package-two```<br />
        * ```# pacman -Rs package-one package-two```<br />
      * The only exception is if the help option is used. If so, all other options and operations are ignored.

### Options
  * --help (used by Instaur, not passed to pacman)<br />
      * Displays the README file. No packages will be installed when this is activated. This option can also be used with one or no dashes.<br />
  * --noconfirm (used by Instaur and passed to pacman)<br />
      * Bypasses any confirmation dialogs. Warning: Make sure any dependencies are taken care of before using this.<br />
  * --needed (used by Instaur and passed to pacman)<br />
      * Does not reinstall packages that are up to date.<br />

#### Other pacman options
Any other pacman options may be added to Instaur in the same manner as --noconfirm or --needed. However, Instaur is only written to take the above three into consideration. Any other options will be passed straight to pacman and otherwise ignored by Instaur. Instaur executes the -S operation using ```# pacman -U *.xz```. Additional pacman options will be passed like so: ```# pacman -U opt1 opt2 opt3 *.xz``` Only use options that are compatible with the selected operation. Most pacman options are untested with Instaur. pacman options can be viewed here: https://www.archlinux.org/pacman/pacman.8.html. Use at your own risk.
