smartsdr-objective-c
====================

Objective C Libraries for access to SmartSDR

STATUS: THIS REPO IS UNDER ACTIVE DEVELOPMENT.  USE AT YOUR OWN RISK AND BE
AWARE THAT SOME ASPECTS OF THE INTERFACE WILL CHANGE.                        

FOR ANY QUESTIONS, DEFECT REPORTS OR SUGGESTIONS, CONTACT STU PHILLIPS, K6TU
DIRECTLY.  THIS SOFTWARE IS NOT SUPPORTED OR REVIEWED BY FLEXRADIO SYSTEMS SO
DON'T BUG THEM WITH QUESTIONS.

This repo contains the Model classes to access and control a FlexRadio Systems
6000 series radio via its Ethernet API.  The model comprises the following
classes:

	RadioFactory	- Reports discovered radios
	Radio		- The primary interface to a specific radio
	Slice		- Instantiated for each active slice on the Radio
	Pandaptor	- FUTURE
	Meter		- FUTURE

The RadioFactory and Radio classes are dependent upon the CocoaAysncSocket
class written by Robbie Hanson and available freely at:

	https://github.com/robbiehanson/CocoaAsyncSocket

Instantiate the RadioFactory to begin the process of discovering radios on
the network.  A notification is available for whenever a radio is discovered
or disappears via a timeout.

Instantiate a Radio class on a RadioInstance manufactured by the RadioFactory
to access & control a specific radio.  The Radio class properties reflect the
status and controls which are radio specific such as transmit power level,
transmitter controls etc as there is a SINGLE transmitter in each radio.  
Notifications are sent when a slice is created or deleted.

The Radio class instantiates the Slice class for each slice existing on the 
Radio instance.  A Slice is a logical receiver and is connected to an antenna
port.  Each slice has unique attributes such as receive mode, audio & DSP
controls etc which are maintained as properties.

There are MANY changes from version 1.6 (current top of master) so be warned...

THIS CODE IS ALPHA LEVEL, will break your existing applicaiton using any earlier
version and isn't fully tested.

"Don't say I didn't say I didn't warn ya!'" - Taylor Swift, Blank Space from 1989

Major Changes:

1. The majority of command methods on both Radio and Slice have been eliminated
   and replaced by commands to the radio being generated from setter methods of 
   appropriate properties.  So for example, use self.sliceFrequency = freq to 
   change the frequency of the slice.

2. Radio and Slice properties are still in object form - ie NSNumber instead of 
   the underlying numbers.  This *may* change in the future...

3. Almost all of the models now run on private run queues but signal KVO changes
   on the main default run queue.

4. Models now exist for Meters, Panafall and Waterfall streams.  In the case of 
   the Meter, incoming meters are processed on the VitaManager's private run queue
   and the meter is updated on the default queue.  Both Panafall and Waterfall
   expect to run on a run queue other than the default run queue and a delegate
   may provide their own run queue.  Updating the delegate and the runqueue uses
   syncrhonized and should be thread safe.


