### What is this repository for? ###

* This repository holds the firmware components and test software for the ProtoDUNE-SP timing system
* Current version is relval/v5b0-3 (clone from tags/relval/v5b0-3 )

### How do I get set up? ###

The master firmware uses the [ipbb](https://github.com/ipbus/ipbb) build tool, and requires the ipbus system firmware.
The following example procedure should build a board image for testing of the timing FMC. Note that a reasonably up-to-date
operating system (e.g. Centos7) is required.  You will need to run the scripts using python2.7 (not python3).  If you are 
going to build on a computer outside of the CERN network, then you will need to run kerberos (kinit username@CERN.CH)).
These instructions build the "ourobouros" design with timing master and timing endpoint implemented in an Enclustra AX3 with Artix-35
mounted on a PM3 motherboard connected to a pc053a timing FMC. They assume that you have your Xilinx Vivado licensing already setup for your environment.
    # This first step isn't needed if you already have a CERN kerberos token loaded into your session
	# Obviously, replace my_username_at_CERN with your actual username ....
	kinit my_username_at_CERN@CERN.CH

	mkdir work
	cd work
	curl -L https://github.com/ipbus/ipbb/archive/dev/2020g.tar.gz | tar xvz
	source ipbb-dev-2020g/env.sh 
	ipbb init build
	cd build
	ipbb add git https://github.com/ipbus/ipbus-firmware.git -b v1.8
	ipbb add git https://:my_username_at_CERN@gitlab.cern.ch:8443/protoDUNE-SP-DAQ/timing-board-firmware.git
	ipbb proj create vivado top_a35 timing-board-firmware:projects/ouroboros top_a35_ax3_pm3_pc053d.dep
	cd proj/top_a35
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
* Alessandro Thea (alessandro.thea@cern.ch)

