# PRTG-iDirect-sensor
Custom iDirect XML Sensor for PRTG

Please the iDirect.ps1 file in the Custom Sensors\EXEXML\ folder and put the *.ovl in lookups\custom\

Restart your PRTG Core server after that.

Create a Advanced EXE/XML sensor and select my iDirect.ps1 script from the drop down.

Pass the following string as parameters,

-User %linuxserver -Password %linuxpassword -RemoteHost %host

Make sure you have specified the correct login credentials (the Linux ones).

If you want to enable Change State notifications for Beam changes, then you have to make sure this is the Primary Channel for the sensor.

I suggest you use "%device %lastmessage" as the email/push notification subject.
