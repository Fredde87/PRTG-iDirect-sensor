# PRTG-iDirect-sensor
## Custom iDirect XML Sensor for PRTG

1. Please the iDirect.ps1 file in the Custom Sensors\EXEXML\ folder and put the *.ovl in lookups\custom\

2. Restart your PRTG Core server after that.

3. Create a Advanced EXE/XML sensor for your iDirect modem's Sensor and select my iDirect.ps1 script from the drop down.

4. Pass the following string as parameters,
-User %linuxserver -Password %linuxpassword -RemoteHost %host

5. Make sure you have specified the correct login credentials (the Linux ones) for your iDirect Sensor.

6. (Optional). If you want to enable Change State notifications for Beam changes, then you have to make sure this is the Primary Channel for the sensor.
- I suggest you use "%device %lastmessage" as the email/push notification subject.
