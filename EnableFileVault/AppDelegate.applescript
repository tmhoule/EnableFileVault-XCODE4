--
--  AppDelegate.applescript
--  EnableFileVault
--
--  Created by admin on 5/21/14.
--  Copyright (c) 2014 Partners. All rights reserved.
--

script AppDelegate
	property parent : class "NSObject"
    property userToUse : "" --admin user name
	property passToUse : "" --users password
	property theWindow : missing value
    property statusText : "Note: This program will automatically restart the computer."
    property isWorkingNow : false
    property statusTextLine2 : ""
    
    global shouldContinue
    global OSVers
    global encryptStatus
    
	on applicationWillFinishLaunching_(aNotification)
		-- Insert code here to initialize your application before any files are opened
        set shouldContinue to true

        --look for Recovery Partition here.
		set RecoveryExists to ""
		try
			set RecoveryExists to (do shell script "diskutil list |grep Recovery")
		end try
        log "Enable FV: RecoveryExists is " & RecoveryExists
		if RecoveryExists is "" then
            set my statusText to "WARNING: No Recovery Partition Found.  Continue at your own risk!"
            set shouldContinue to false
		end if
        
        --look for FileVault Master keychain
		set validFVKey to do shell script "md5 /Library/Keychains/FileVaultMaster.keychain|awk -F= '{print $2}'"
		if validFVKey is not equal to " dc7aaf54b8a52c17c37a11195f1d1c23" then
            set my statusText to "Invalid FileVault Key.  Please reinstall from Self Service."
            set shouldContinue to false
		end if
        
        --Look for OS X 10.7
		set OSVersFull to do shell script "/usr/bin/sw_vers -productVersion"
		set OSVers to (characters 1 thru -3 of OSVersFull) as string
        log "Enable FV Found OS Version " & OSVers
		if OSVers is not "10.7" then
            set my statusText to "WARNING: This application is written for 10.7 only, not " & OSVers & "."
            set shouldContinue to false
		end if

        --look for encryption already done
        set encryptStatus to "EncryptionDone"
        try
            set testString to do shell script "diskutil cs list|grep \"CoreStorage logical volume groups (\""
            on error
            set encryptStatus to "Ready to Go"
        end try
        
        if encryptStatus is "EncryptionDone" then
            set my statusText to "NOTE: Encryption appears to be done already."
            set shouldContinue to false
        end if
        
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminate_(sender)
		-- Insert code here to do any housekeeping before your application quits 
		return current application's NSTerminateNow
	end applicationShouldTerminate_
	
    
    on beginLook_(sender)
        if encryptStatus is "EncryptionDone" then
            display dialog "Congratulations! Encryption appears to be done already. No need to run this program!" buttons "OK" default button 1
        end if
        
        if OSVers is not "10.7" then
            display dialog "You are not running Mac OS X 10.7 Lion.  This tool will not work on other OS Versions." buttons "OK" default button 1
        end if
        
        if shouldContinue is false
            set my statusTextLine2 to "Error: Fix problems above before running."
            tell theWindow to displayIfNeeded()
            do shell script "sleep 3"
            set my statusTextLine2 to ""
            exit  --i know, not valid but it does exit!
        end if
        set my isWorkingNow to true
		tell theWindow to displayIfNeeded()
		theWindow's makeFirstResponder_(missing value)
		
		--get path to root folder
        log "Enable FV Initializing"
		set rootPath to current application's NSBundle's mainBundle()'s resourcePath() as text
		set oldDelimiters to AppleScript's text item delimiters -- always preserve original delimiters
		set AppleScript's text item delimiters to {"/"}
		set pathItems to text items of (rootPath as text)
		set numItems to (number of items of pathItems)
		set fewFewer to (numItems - 2) --in main app bundle
		set fewFewer2 to (numItems - 3) --To This App
		set rootPathB to ((items 1 thru fewFewer of pathItems as string)) --gets path to root imaging folder
		set appPath to (items 1 thru fewFewer2 of pathItems as string) --path to this application
		set AppleScript's text item delimiters to oldDelimiters -- revert original delimiters
		

				
		--get boot disk name
		set diskID to (do shell script "diskutil info / | grep \"Device Identifier\"|awk '{print $3}'")
        log "getting target disk: " & diskID
    
        --update status to Starting
        set my statusText to "Status: Enabling Encryption, please wait..."
        set my statusTextLine2 to ""
        tell theWindow to displayIfNeeded()

        --give final notice.  No display dialog via self service, only when manually run
        try
                set diagResults to (display dialog "If other people besides " & userToUse & " will be using this computer, please enable them for FileVault in System Preferences -> Security & Privacy after the reboot." buttons {"Cancel","OK"} default button 2)
                if button returned of diagResults is "Cancel"
                    tell me to quit
                end if
        end try
        
		--start csfde
        log "Beginning encryption routine."
		try
            do shell script ("\"" & rootPathB & "/Contents/Resources/csfde\" " & diskID & " " & userToUse & " " & passToUse) user name userToUse password passToUse  --with administrator privileges
            set my statusText to "Status: Finished. Rebooting Now...."
            tell theWindow to displayIfNeeded()
            do shell script "sleep 3"
            tell application "System Events"
                restart
            end tell
        on error
            log "Error occured during encryption routine."
            set my isWorkingNow to false
            set my statusText to "ERROR: Encryption could not be enabled.  "
            set my statusTextLine2 to "Please confirm the username and password and try again."
            tell theWindow to displayIfNeeded()
		end try

        set isWorkingNow to false
	end beginLook_


    on quit_(sender)
        tell me to quit
    end quit_
end script