# Simulating (Proto)DUNE Timing System

## How do I get set up? ##

The master firmware uses the [ipbb](https://github.com/ipbus/ipbb) build tool, and requires the ipbus system firmware.
The following example procedure should build a simulation using QuestaSim

These instructions assume that you have Vivado 2018.3 and QuestaSim 10.6c installed and in your PATH

	mkdir work
	cd work
	curl -L https://github.com/ipbus/ipbb/archive/v0.5.2.tar.gz | tar xvz
	source ipbb-0.5.2/env.sh 
	ipbb init build
	cd build
	ipbb add git https://github.com/ipbus/ipbus-firmware.git -b v1.6
	# Caution - the line below uses the Master branch. Here Be Dragons.
	ipbb add git https://:@gitlab.cern.ch:8443/protoDUNE-SP-DAQ/timing-board-firmware.git -b master 
	ipbb proj create sim  pdts_ourobouros_sim timing-board-firmware:projects/ouroboros -t top_sim.dep
	cd proj/pdts_ourobouros_sim 
	ipbb sim setup-simlib ipcores mifs fli-udp -p 50010
	ipbb sim make-project
	ipbb sim addrtab
	deactivate

## How to I run the simulation ##


	./vsim
	vsim top.work
	run -all

## How do I run pdtbutler to interact with simulation?

Assuming that your working directory is work/build/proj setup pdtbutler with....

	ipbb add git https://:@gitlab.cern.ch:8443/protoDUNE-SP-DAQ/timing-board-software.git
	pushd ../../src/timing-board-software/
	make
	. ./tests/env.sh

Now run pdtbutler 

	pdtbutler io  SIM_UDP reset

The response should be something like:

	Created device SIM_UDP
	Design 'ouroboros-sim' on board 'sim' on carrier 'enclustra-a35'
	Resetting SIM_UDP

It should also be possible to write to the current timestamp register

	bash-4.2$ pdtbutler mst SIM_UDP synctime 
	Created device SIM_UDP
	ID: design 'ouroboros-sim' on board 'sim' on carrier 'enclustra-a35'
	Master FW rev: 0x50100, partitions: 1, channels: 1
	Old Timestamp 0x11ac70ce4419a96
	New Timestamp 0x11ac71297b1910e
	-0.03395652771
	Thu, 11 Jun 2020 18:28:42 +0000

Configure the master

```
	bash-4.2$ pdtbutler mst SIM_UDP part 0 configure
	Created device SIM_UDP
	ID: design 'ouroboros-sim' on board 'sim' on carrier 'enclustra-a35'
	Master FW rev: 0x50100, partitions: 1, channels: 1
	Configuring partition 0
	Trigger mask set to 0xf1
 	 Fake mask 0x1
 	 Phys mask 0xf
	Partition 0 enabled and configured
```
Interogate the master's status


```
bash-4.2$ pdtbutler mst SIM_UDP part 0 status
Created device SIM_UDP
ID: design 'ouroboros-sim' on board 'sim' on carrier 'enclustra-a35'
Master FW rev: 0x50100, partitions: 1, channels: 1

-- Master state---

=> Cmd generator counters
----------------------------------------------------------------------------
|              |       Accept counters       |       Reject counters       |
----------------------------------------------------------------------------
|     Chan     |     cnts     |     hex      |     cnts     |     hex      |
----------------------------------------------------------------------------
|     0x0      |      0       |     0x0      |      0       |     0x0      |
----------------------------------------------------------------------------

=> Partition 0
Control                   Status registers  
+---------------+------+  +----------+-----+
| buf_en        | 0x0  |  | buf_err  | 0x0 |
| frag_mask     | 0x0  |  | buf_warn | 0x0 |
| part_en       | 0x1  |  | in_run   | 0x0 |
| rate_ctrl_en  | 0x1  |  | in_spill | 0x0 |
| run_req       | 0x0  |  | part_up  | 0x1 |
| spill_gate_en | 0x1  |  | run_int  | 0x0 |
| trig_ctr_rst  | 0x0  |  +----------+-----+
| trig_en       | 0x0  |                    
| trig_mask     | 0xf1 |                    
+---------------+------+                    

Timestamp: 0x11aca0885939c50 -> Fri, 12 Jun 2020 12:33:47 +0000
EventCounter: 0
Buffer status: OK
Buffer occupancy: 0

----------------------------------------------------------------------------
|              |       Accept counters       |       Reject counters       |
----------------------------------------------------------------------------
|     Cmd      |     cnts     |     hex      |     cnts     |     hex      |
----------------------------------------------------------------------------
|   TimeSync   |      10      |     0xa      |      0       |     0x0      |
|     Echo     |      0       |     0x0      |      0       |     0x0      |
|  SpillStart  |      0       |     0x0      |      0       |     0x0      |
|  SpillStop   |      0       |     0x0      |      0       |     0x0      |
|   RunStart   |      0       |     0x0      |      0       |     0x0      |
|   RunStop    |      0       |     0x0      |      0       |     0x0      |
|   WibCalib   |      0       |     0x0      |      0       |     0x0      |
|   SSPCalib   |      0       |     0x0      |      0       |     0x0      |
|  FakeTrig0   |      0       |     0x0      |      0       |     0x0      |
|  FakeTrig1   |      0       |     0x0      |      0       |     0x0      |
|  FakeTrig2   |      0       |     0x0      |      0       |     0x0      |
|  FakeTrig3   |      0       |     0x0      |      0       |     0x0      |
|   BeamTrig   |      0       |     0x0      |      0       |     0x0      |
|  NoBeamTrig  |      0       |     0x0      |      0       |     0x0      |
| ExtFakeTrig  |      0       |     0x0      |      0       |     0x0      |
|     0xf      |      0       |     0x0      |      0       |     0x0      |
----------------------------------------------------------------------------
```


## How do I update my versions of python2 click , click-didyoumean

You will need python2 package `click` >= 7.0

	sudo pip install --upgrade pip
	sudo pip install --upgrade click
