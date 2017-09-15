Param (
        [string]$User = "",
        [string]$Password = "",
        [string]$RemoteHost = "",
        [string]$WarnLvlRxSNR = "7",
        [string]$ErrorLvlRxSNR = "5",
        [string]$WarnLvlTxPower = "-18",
        [string]$ErrorLvlTxPower = "-15"
 )
    
Function Get-Telnet
{   Param (
        [String[]]$Commands = @(""),
        [string]$Port = "23",
        [int]$WaitTime = 1000
    )
    #Attach to the remote device, setup streaming requirements
    $Socket = New-Object System.Net.Sockets.TcpClient($RemoteHost, $Port)

    Write-Host "<?xml version="1.0" encoding="Windows-1252" ?><prtg>"

    If ($Socket)
    {   $Stream = $Socket.GetStream()
        $Writer = New-Object System.IO.StreamWriter($Stream)
        $Buffer = New-Object System.Byte[] 1024 
        $Encoding = New-Object System.Text.AsciiEncoding

        #Now start issuing the commands
        ForEach ($Command in $Commands)
        {   $Writer.WriteLine($Command) 
            $Writer.Flush()
            Start-Sleep -Milliseconds $WaitTime
        }
        #All commands issued, but since the last command is usually going to be
        #the longest let's wait a little longer for it to finish
        Start-Sleep -Milliseconds ($WaitTime * 4)
        $Result = ""
        #Save all the results
        While($Stream.DataAvailable) 
        {   $Read = $Stream.Read($Buffer, 0, 1024) 
            $Result += ($Encoding.GetString($Buffer, 0, $Read))
        }
        Return $Result
    }
    Else     
    {
       Write-Host "<Text> Error connecting to $Host</Text><Error>1</Error>"
       Write-Host '</prtg>'
         Exit 1
    }
}

#
$Process = Get-Telnet -Commands "$User","$Password","rx snr", "tx refpower", "txstate", "beamselector list", "quit"



$BeamNum = [regex]::Match($Process, '(.+) is currently selected').Groups[1].Value -replace "`n|`r"

$BeamName = [regex]::Match($Process, "$($BeamNum)\s+=\s+(.+)").Groups[1].Value -replace "`n|`r"


$TxStateString = [regex]::Match($Process, 'TX State\s+:\s+(.+)').Groups[1].Value -replace "`n|`r"

If($TxStateString -clike 'ON') {
    $TxState = 1
} elseif ($TxStateString -clike 'Warning') {
    $TxState = 2
} else {
    $TxState = 0
}

$DemodStatusString = [regex]::Match($Process, 'Demod Status\s+:\s+(.+)').Groups[1].Value -replace "`n|`r"



If($DemodStatusString -eq "Locked") {
    $DemodStatus = 1
} else {
    $DemodStatus = 0
}

$NCRStatusString = [regex]::Match($Process, 'NCR Status\s+:\s+(.+)').Groups[1].Value -replace "`n|`r"

If($NCRStatusString -clike 'Locked') {
    $NCRStatus = 1
} else {
    $NCRStatus = 0
}

$TxMuteString = [regex]::Match($Process, 'Tx Mute\s+:\s+(.+)').Groups[1].Value -replace "`n|`r"

If($TxMuteString -clike 'False') {
    $TxMute = 0
} else {
    $TxMute = 1
}

$NetworkKeyString = [regex]::Match($Process, 'Network Key\s+:\s+(.+)').Groups[1].Value -replace "`n|`r"

If($NetworkKeyString -clike 'Valid') {
    $NetworkKey = 1
} else {
    $NetworkKey = 0
}


$TxCarrierInfoString = [regex]::Match($Process, 'Tx Carrier Info\s+:\s+(.+)').Groups[1].Value -replace "`n|`r"

If($TxCarrierInfoString -clike 'Valid') {
    $TxCarrierInfo = 1
} else {
    $TxCarrierInfo = 0
}


$TxAuthString = [regex]::Match($Process, 'Tx Authorization\s+:\s+(.+)').Groups[1].Value -replace "`n|`r"

If($TxAuthString -clike 'Valid') {
    $TxAuth = 1
} else {
    $TxAuth = 0
}

$OperatingModeString = [regex]::Match($Process, 'Operating Mode Mismatch\s+:\s+(.+)').Groups[1].Value -replace "`n|`r"

If($OperatingModeString -clike 'True') {
    $OperatingMode = 1
} else {
    $OperatingMode = 0
}

$MissedBTPCount = [regex]::Match($Process, 'Missed BTP Count\s+:\s+(.+)').Groups[1].Value -replace "`n|`r"
$MismatchedBTPCount = [regex]::Match($Process, 'Mismatched BTP Count\s+:\s+(.+)').Groups[1].Value -replace "`n|`r"
$BTPSeqNum = [regex]::Match($Process, 'BTP Seq-Num UnAvailable\s+:\s+(.+)').Groups[1].Value -replace "`n|`r"
   
   
   


$RefPower = [regex]::Match($Process, 'Tx Reference Power\s+=\s+(.+) dbm').Groups[1].Value -replace "`n|`r"


$RxSNR = [regex]::Match($Process, 'SNR:\s+(.+)00').Groups[1].Value -replace "`n|`r"


Write-Host "
<result>
       <channel>Beam Number</channel>
       <unit>Custom</unit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>$($BeamNum)</value>
"

If(Test-Path $Env:temp\beam.txt) {
    $OldBeam = Get-Content -Path $Env:temp\beam.txt
    If ("$OldBeam" -ne "$($BeamName) ($($BeamNum))")  {
        Write-Host "<NotifyChanged>1</NotifyChanged>
        "
    }
}
Write-Output "$($BeamName) ($($BeamNum))" | Out-File -Force -NoNewline $Env:temp\beam.txt
Write-Host "</result>"


Write-Host "
<result>
       <channel>RX SNR</channel>
       <unit>Custom</unit>
       <customUnit>dB</customUnit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>1</float>
       <value>$($RxSNR)</value>
       <LimitMinError>$($ErrorLvlRxSNR)</LimitMinError>
       <LimitMinWarning>$($WarnLvlRxSNR)</LimitMinWarning>
       <LimitWarningMsg>Rx SNR is low</LimitWarningMsg>
       <LimitErrorMsg>Rx SNR is extremely low</LimitErrorMsg>
       <LimitMode>1</LimitMode>
</result>"


Write-Host "
<result>
       <channel>TX RefPower</channel>
       <unit>Custom</unit>
       <customUnit>dB</customUnit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>1</float>
       <value>$($RefPower)</value>
       <LimitMaxError>$($ErrorLvlTxPower)</LimitMaxError>
       <LimitMaxWarning>$($WarnLvlTxPower)</LimitMaxWarning>
       <LimitWarningMsg>This is higher than normal...    </LimitWarningMsg>
       <LimitErrorMsg>Is there a reason for this? (bad weather etc)...    </LimitErrorMsg>
       <LimitMode>1</LimitMode>
   </result>"



Write-Host "
<result>
       <channel>Tx State</channel>
       <unit>Custom</unit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>$($TxState)</value>
       <ValueLookup>idirect.preferon</ValueLookup>
   </result>"

Write-Host "
<result>
       <channel>Demod Status</channel>
       <unit>Custom</unit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>$($DemodStatus)</value>
       <ValueLookup>idirect.preferlocked</ValueLookup>
   </result>"

Write-Host "
<result>
       <channel>NCR Status</channel>
       <unit>Custom</unit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>$($NCRStatus)</value>
       <ValueLookup>idirect.preferlocked</ValueLookup>
   </result>"

Write-Host "
<result>
       <channel>Tx Mute</channel>
       <unit>Custom</unit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>$($TxMute)</value>
       <ValueLookup>idirect.preferfalse</ValueLookup>
   </result>"

Write-Host "
<result>
       <channel>Network Key</channel>
       <unit>Custom</unit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>$($NetworkKey)</value>
       <ValueLookup>idirect.prefervalid</ValueLookup>
   </result>"

Write-Host "
<result>
       <channel>Tx Carrier Info</channel>
       <unit>Custom</unit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>$($TxCarrierInfo)</value>
       <ValueLookup>idirect.prefervalid</ValueLookup>
   </result>"

Write-Host "
<result>
       <channel>Tx Authorization</channel>
       <unit>Custom</unit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>$($TxAuth)</value>
       <ValueLookup>idirect.prefervalid</ValueLookup>
   </result>"

Write-Host "
<result>
       <channel>Operating Mode Mismatch</channel>
       <unit>Custom</unit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>$($OperatingMode)</value>
       <ValueLookup>idirect.preferfalse</ValueLookup>
   </result>"

Write-Host "
<result>
       <channel>Missed BTP Count</channel>
       <unit>Custom</unit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>$($MissedBTPCount)</value>
   </result>"

Write-Host "
<result>
       <channel>Mismatched BTP Count</channel>
       <unit>Custom</unit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>$($MismatchedBTPCount)</value>
   </result>"

Write-Host "
<result>
       <channel>BTP Seq-Num UnAvailable</channel>
       <unit>Custom</unit>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>$($BTPSeqNum)</value>
   </result>
   "

If ($TxMute -eq 1) {
    Write-Host "<Text>Transmit is muted. Most likely both antennas are in blockage.</Text>"
    Write-Host "<Error>0</Error>"   
} elseif ("$OldBeam" -ne "$($BeamName) ($($BeamNum))") {
    Write-Host "<Text>just changed from beam: $($OldBeam) to $($BeamName) ($($BeamNum)), Rx SNR: $($RxSNR)dB, Tx Power: $($RefPower)dBm</Text>"
    Write-Host "<Error>0</Error>"       
} else {
    Write-Host "<Text>$($BeamName) ($($BeamNum)), Rx SNR: $($RxSNR)dB, Tx Power: $($RefPower)dBm</Text>"
    Write-Host "<Error>0</Error>"       
}

Write-Host '</prtg>'

exit 0