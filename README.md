QMLBenchrunner
==============

Developed by Eskil Blomfeldt
Adapted for Windows by Daniel Smith

QMLBenchrunner is a simple script and python application to programmatically 
clone a Qt Git repository, run associated QML Benchmark tests, and post
results to the qt testresults timeseries database.


Prerequisites
-------------


- Python3
	Python3 module dependencies:
		- requests

Windows-specific Prerequsites:
* An MSVC2015+ 32-bit Prebuilt Components installation of Qt 5.10.0 or later. (Earlier versions have not been tested)
* ActivePerl - Download and install from http://www.activestate.com/Products/activeperl/index.mhtml
* GPerf - Download and install from http://gnuwin32.sourceforge.net/downlinks/gperf.php
* Flex & Bison for windows - Included with qmlbenchrunner, or downloadable from 
&nbsphttp://sourceforge.net/projects/winflexbison/files/win_flex_bison-2.5.5.zip/download
&nbspIf Win Flex-Bison is downloaded, you must rename the executables to "flex.exe" and "bison.exe"
&nbspand specify the location of your flex-bison executables using the powershell parameter specified in the paramters
&nbspsection below.
* JOM - A version is included with qmlbenchrunner. If a new version is required, it can be found at https://wiki.qt.io/Jom


Usage
-----

QMLBenchrunner will clone copies of required Qt Git repositories as well as qmlbench into the working directory.
Is is best practice to run qmlbenchrunner from a parent directory so that the cloned repos are not cloned into the
qmlbenchrunner directory directly. See the examples below.

Always set environment variables INFLUXDBUSER and INFLUXDBPASSWORD in the console before calling the build_and_test
script. Results will still be saved to disk in "results.json" even if unable to write to the database.

### Linux: ###
	Some machines may require XAUTHORITY to be specified. If problems are encountered, set XAUTHORITY and DISPLAY in
	the console before running this script.

	### build_and_test.sh arguments are strictly positional. Do not skip arguments that are required. ###

	Args:	QtVersion (required) | MachineName (required) | BuildCores (required) |
			Annotate (required, set to "False" if not desired) | QtDeclaritiveVersion (optional, leave missing if same as main QtVersion)
	
	Example:
	export INFLUXDBUSER=dbuser1
	export INFLUXDBPASSWORD=dbuser1password
	export XAUTHORITY=/home/user1/.Xauthority
	export DISPLAY=:0
	qmlbenchrunner/build_and_test.sh 5.6 $NODE_NAME 8 annotate

### Windows: ###
	Qmlbenchrunner should be executed from Powershell for best compatibility. Because QMLBench is a graphical application, if
	qmlbenchrunner is being executed via a jenkins slave, the slave must use the java web start method. Running jenkins as a
	Windows service will not display QMLBench on the real user desktop.

	Args:
		QtVersion (Required)
		MachineName (Required)
		BuildCores (Optional)
		Annotate (Optional)
		QtDeclarativeVersion (Optional)
		WinDeployDir (Optional, defaults to "C:\Qt\5.11.0\msvc2015\bin\" if omitted)
		FlexBisonDir = (Optional, defaults to "[current working directory]\flex_bison\" if omitted)

	Example:
		$env:INFLUXDBUSER=dbuser1
		$env:INFLUXDBPASSWORD=dbuser1password
		.\qmlbenchrunner\build_and_test_windows.ps1 -QtVersion 5.11 -BuildCores 7 -MachineName $ENV:NODE_NAME -WinDeployDir C:\Qt\msvc2015\bin -FlexBisonDir C:\flex_bison -Annotate

### MacOS X: ###
	See instructions for Linux. Some trouble has been observed with Jenkins OSX clients not setting PATH correctly. If you experience 
	issues when submitting results to a database, make sure that Python3 is set in the PATH environment variable used by Jenkins scripts.

	Example:
	export PATH+=:/Library/Frameworks/Python.framework/Versions/3.6/bin/
	qmlbenchrunner/build_and_test.sh dev $NODE_NAME 4 annotate

### Embedded ###
	The build_and_test_embedded.sh script is inteded to be used with a Jenkins host, but can be used on it's own. The script file will need to be modifed based on your specific environment as detailed below.
	
	Terminology for this section:
		Host - The machine this script will run on.
		Client - The target embedded device that will execute QMLBench.

	Assumptions:
	1) The host is configured for cross-compilation to a given target device.
	2) An official Boot2Qt SDK is installed on the host.
	3) The target embedded device (client) is accessible via SSH over a local network by IP and the host has connected to it at least once.
	4) The host is accessible via ssh over a local network by IP and the host's ssh configuration is configured to accept connections from the client.

	Required script alterations:
	1) Update the sysrootDir with your Boot2Qt version number. (line 16)
	2) Update the user and IP of the host in order to pass the results.json file back from the client. (line 128)

	Required host configuration:
	1) Before running the script, the following environment variables must be set.

	DEVMKSPEC=linux-imx6-g++
	DEVNAME=apalis-imx6
	CROSSCOMPILE=x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-
	ARMSYSROOT=cortexa9hf-neon-poky-linux-gnueabi
	DEVIP=10.9.70.70
	INFLUXDBUSER=username #Set if writing to a database.
	INFLUXDBPASSWORD=password #Set if writing to a database.

	Running the script:
	### build_and_test_embedded.sh arguments are strictly positional. Do not skip arguments that are required. ###

	Args:	QtVersion (required) | MachineName (required) | BuildCores (required) |
			Annotate (required, set to "False" if not desired) | QtDeclaritiveVersion (optional, leave missing if same as main QtVersion)
	
	qmlbenchrunner/build_and_test_embedded.sh 5.6 $NODE_NAME 8 annotate


	Required client configuration:
	1) Verify that at least 1GB of free space exists on the client.
	NB! This script will wipe out /opt/qt on the client if there is insufficient space on the device. Verify that this directory does not contain anything you want to keep.
