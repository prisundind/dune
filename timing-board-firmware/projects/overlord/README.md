### Building PDTS "Overlord" Firmware for AIDA-TLU ###

* This ipbb project builds the Overlord design (system master) targeting the AIDA2020 TLU
* Current version is relval/v5b0-3 (clone from tags/relval/v5b0-3 )

### How do I get set up? ###

The master firmware uses the [ipbb](https://github.com/ipbus/ipbb) build tool, and requires the ipbus system firmware.
The following example procedure should build a board image for testing of the timing FMC. Note that a reasonably up-to-date
operating system (e.g. Centos7) is required.  You will need to run the scripts using python2.7 (not python3).  If you are 
going to build on a computer outside of the CERN network, then you will need to run kerberos (kinit username@CERN.CH)).
These instructions build the "overlord" design with timing master and timing endpoint implemented in an Enclustra AX3 with Artix-35 
mounted on a PM3 motherboard connected to a AIDA-2020 TLU. They assume that you have your Xilinx Vivado licensing already setup for your environment.

	mkdir work
	cd work
	curl -L https://github.com/ipbus/ipbb/archive/v0.5.2.tar.gz | tar xvz
	source ipbb-0.5.2/env.sh 
	ipbb init build
	cd build
	ipbb add git https://github.com/ipbus/ipbus-firmware.git -b v1.4
	ipbb add git https://:@gitlab.cern.ch:8443/protoDUNE-SP-DAQ/timing-board-firmware.git -b relval/v5b0-3 
	ipbb proj create vivado top timing-board-firmware:projects/overlord -t top_tlu.dep
	cd proj/top
	ipbb vivado project
	ipbb vivado impl
	ipbb vivado bitfile
	ipbb vivado package
	deactivate

### Who do I talk to? ###

* David Cussans (david.cussans@bristol.ac.uk)
* Stoyan Trilov (stoyan.trilov@bristol.ac.uk)
* Sudan Paramesvaran (sudan@cern.ch)
* Dave Newbold (dave.newbold@cern.ch)

