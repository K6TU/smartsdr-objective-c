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

The properties of Radio and Slice classes are KVO compliant and should be considered READ ONLY.  Use the cmd actions for each class to change their attributes.
