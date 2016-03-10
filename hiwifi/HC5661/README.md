Here are the ROMs with the following modifications from the official versions:
   1. Enabled Dropbear SSH server
   2. Enabled console port shell access
   3. Changed the bootloader to version 9003 which allows 3rd party squashfs images


9010 ~ 9016 have all been successfully ROOT'ed.
9017 failed when kernel tries to mount the root file system. Guessing the kerenl is also checking if the squashfs has been modified.


