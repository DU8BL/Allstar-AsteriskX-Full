# Allstar-AsteriskX-Full
Allstar Asterisk Xtended DEB packages with features inspired by HamVoIP for the amd64 architecture
* Supported on Debian 11, 12, and newer versions
* Install using the provided installation script
* DAHDI version 3.4.0

NOTE: This will remove any existing AllStarLink and DAHDI installations. Make sure to create a backup of your configurations beforehand.

-----------------------------------------------------------

### What is included in the deb packages:

* DAHDI, binaries, modules, configs, sounds, etc.

-----------------------------------------------------------

### Compatibility:

* The DAHDI package is compatible with kernel version 6.X and above.
* The package may also work with other Linux distributions, though it is primarily tested on Debian 11, 12, and newer versions.

### Submitting Issues:

* If you encounter any issues, please submit them to the repository's issue tracker.

### Notes for Large Hub operation:

* For fewer than 60-80 directly connected nodes, 1 CPU/vCPU is sufficient.
* For 80 or more directly connected nodes, 2 or more CPUs/vCPUs are recommended.

-----------------------------------------------------------

### How to install (Debian):

* To install the Allstar-AsteriskX-Full packages on Debian, follow these steps (must be run as ROOT):

<pre>
wget https://raw.githubusercontent.com/DU8BL/Allstar-AsteriskX-Full/main/install.sh
chmod +x install.sh
./install.sh
</pre>

* Service Commands:

<pre>
service start asterisk
service stop asterisk
service reload asterisk
</pre>

-----------------------------------------------------------

### Copyright

Asterisk 1.4.23pre is copyright Digium (https://www.digium.com)

app_rpt and associated programs (app_rpt suite) are copyright Jim Dixon, WB6NIL; AllStarLink, Inc.; and contributors

DVSwitch packages are copyright Steve Zingman, N4IRS; Michael Zingman, N4IRR; and contributors
