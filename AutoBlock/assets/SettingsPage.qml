import bb.cascades 1.0
import bb.cascades.pickers 1.0
import com.canadainc.data 1.0

Page
{
    titleBar: TitleBar {
        title: qsTr("Settings") + Retranslate.onLanguageChanged
    }
    
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    
    actions: [
        ActionItem
        {
            title: qsTr("Backup") + Retranslate.onLanguageChanged
            ActionBar.placement: 'Signature' in ActionBarPlacement ? ActionBarPlacement["Signature"] : ActionBarPlacement.OnBar
            imageSource: "images/menu/ic_backup.png"
            
            onTriggered: {
                console.log("UserEvent: Backup");
                filePicker.title = qsTr("Select Destination");
                filePicker.mode = FilePickerMode.Saver
                filePicker.defaultSaveFileNames = ["autoblock_backup.zip"]
                filePicker.allowOverwrite = true;
                
                filePicker.open();
            }
            
            function onSaved(result) {
                persist.showBlockingToast( qsTr("Successfully backed up to %1").arg( result.substring(15) ), qsTr("OK"), "asset:///images/menu/ic_backup.png" );
            }
            
            onCreationCompleted: {
                updater.backupComplete.connect(onSaved);
            }
        },
        
        ActionItem
        {
            title: qsTr("Restore") + Retranslate.onLanguageChanged
            ActionBar.placement: ActionBarPlacement.OnBar
            imageSource: "images/menu/ic_restore.png"
            
            onTriggered: {
                console.log("UserEvent: Restore");
                filePicker.title = qsTr("Select File");
                filePicker.mode = FilePickerMode.Picker
                
                filePicker.open();
            }
            
            function onRestored(result)
            {
                if (result) {
                    persist.showBlockingToast( qsTr("Successfully restored! The app will now close itself so when you re-open it the restored database can take effect!"), qsTr("OK"), "asset:///images/menu/ic_restore.png" );
                    app.exit();
                } else {
                    persist.showBlockingToast( qsTr("The database could not be restored. Please re-check the backup file to ensure it is valid, and if the problem persists please file a bug report. Make sure to attach the backup file with your report!"), qsTr("OK"), "asset:///images/menu/ic_restore_error.png" );
                }
            }
            
            onCreationCompleted: {
                updater.restoreComplete.connect(onRestored);
            }
        },
        
        ActionItem {
            imageSource: "images/menu/ic_optimize.png"
            title: qsTr("Optimize") + Retranslate.onLanguageChanged
            
            onTriggered: {
                console.log("UserEvent: Optimize");
                busy.running = true;
                helper.optimize();
            }
            
            function onDataReady(id, data)
            {
                if (id == QueryId.Optimize) {
                    busy.running = false;
                    persist.showToast( qsTr("Optimization Complete!"), "", "asset:///images/menu/ic_optimize.png" );
                }
            }
            
            onCreationCompleted: {
                helper.dataReady.connect(onDataReady);
            }
        },
        
        ActionItem {
            imageSource: "images/menu/ic_error_recovery.png"
            title: qsTr("Error Recovery") + Retranslate.onLanguageChanged
            
            onTriggered: {
                console.log("UserEvent: ErrorRecovery");
                app.forceSetup();
                
                persist.showToast( qsTr("Error Recovery triggered!"), "", "asset:///images/menu/ic_error_recovery.png" );
            }
        }
    ]
    
    attachedObjects: [
        FilePicker {
            id: filePicker
            defaultType: FileType.Other
            filter: ["*.zip"]
            
            directories :  {
                return ["/accounts/1000/removable/sdcard/misc", "/accounts/1000/shared/misc"]
            }
            
            onFileSelected : {
                console.log("UserEvent: File Selected", selectedFiles[0]);
                
                if (mode == FilePickerMode.Picker) {
                    updater.restore(selectedFiles[0]);
                } else {
                    updater.backup(selectedFiles[0]);
                }
            }
        }
    ]
    
    ScrollView
    {
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill
        
        Container
        {
            leftPadding: 10; topPadding: 10; rightPadding: 10; bottomPadding: 10
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            
            ActivityIndicator
            {
                id: busy
                horizontalAlignment: HorizontalAlignment.Center
                preferredHeight: 150
                running: false
            }
            
            PersistCheckBox
            {
                key: "sound"
                text: qsTr("Sound") + Retranslate.onLanguageChanged
                
                onCheckedChanged: {
                    if (checked) {
                        infoText.text = qsTr("A sound will be played every time a spam message is blocked.");
                    } else {
                        infoText.text = qsTr("No sound will be played every time a spam message is blocked.");
                    }
                }
            }
            
            PersistCheckBox
            {
                id: blockStrangers
                topMargin: 10
                key: "blockStrangers"
                text: qsTr("Block Non-Contacts") + Retranslate.onLanguageChanged
                visible: false
                
                onCheckedChanged: {
                    if (checked) {
                        infoText.text = qsTr("Messages from anyone who is not on your contact list will be blocked automatically.");
                    } else {
                        infoText.text = qsTr("Messages from senders who are not on your contact list will only be blocked if they are in the blocked senders or send messages with subjects that match your blocked keywords list.");
                    }
                }
            }
            
            PersistCheckBox
            {
                topMargin: 10
                enabled: !blockStrangers.checked
                key: "whitelistContacts"
                text: qsTr("Whitelist All Contacts") + Retranslate.onLanguageChanged
                
                onCheckedChanged: {
                    if (checked) {
                        infoText.text = qsTr("Messages from your contacts will never be marked as spam.");
                    } else {
                        infoText.text = qsTr("Messages from your contacts should still be tested for spam keywords/senders.");
                    }
                }
            }
            
            PersistCheckBox
            {
                topMargin: 10
                key: "startAtConversations"
                text: qsTr("Start At Conversations Tab") + Retranslate.onLanguageChanged
                
                onCheckedChanged: {
                    if (checked) {
                        infoText.text = qsTr("The app will start at the Conversations tab when it is loaded.");
                    } else {
                        infoText.text = qsTr("The app will start at the Logs tab when it is loaded.");
                    }
                }
            }
            
            PersistCheckBox
            {
                id: moveTrash
                topMargin: 10
                key: "moveToTrash"
                text: qsTr("Move Spam to Trash") + Retranslate.onLanguageChanged
                
                onCheckedChanged: {
                    if ( checked && !persist.contains("autoblock_junk") ) {
                        persist.showBlockingToast( qsTr("This is a purchasable feature that will allow spam messages to be moved to the trash folder instead of directly deleting them. Press OK to launch the payment screen."), qsTr("OK"), "file:///usr/share/icons/bb_action_delete.png" );
                        moveTrash.checked = false;
                        payment.requestPurchase("autoblock_junk", "Junk Folder (Move to Trash)");
                    } else {
                        if (checked) {
                            infoText.text = qsTr("The app will move the spam messages to the trash folder instead of directly deleting them. This way if a message is accidentally blocked, you can still go recover it.");
                        } else {
                            infoText.text = qsTr("The app will permanently delete all spam messages. Warning: There is no way to recover these deleted messages with this setting.");
                        }
                    }
                }
            }
            
            Label {
                topMargin: 40
                id: infoText
                multiline: true
                textStyle.fontSize: FontSize.XXSmall
                textStyle.textAlign: TextAlign.Center
                verticalAlignment: VerticalAlignment.Bottom
                horizontalAlignment: HorizontalAlignment.Center
            }
        }
    }
    
    onCreationCompleted: {
        if ( persist.tutorial("tutorialSound", qsTr("Enable the Sound checkbox if you want to hear a sound everytime a message is blocked (this will only sound if you have the device is an appropriate profile that allows notifications)."), "file:///usr/share/icons/cs_audio_caution.png" ) ) {}
        //else if ( persist.tutorial("tutorialBlockStrangers", qsTr("Enable the Block Non-Contacts checkbox if you want to block messages from anyone who is not in your contact list."), "file:///usr/share/icons/ic_open_contacts.png" ) ) {}
        else if ( persist.tutorial("tutorialWhitelist", qsTr("Enable the Whitelist All Contacts checkbox if you want to prevent scanning of messages sent by anyone in your contact list."), "file:///usr/share/icons/add_to_contacts.png" ) ) {}
        else if ( persist.tutorial("tutorialStartConversations", qsTr("Enable the Start At Conversations Tab checkbox if you want the app to start at the Conversations tab instead of the default Logs tab."), "file:///usr/share/icons/ic_tentative.png" ) ) {}
        else if ( persist.tutorial("tutorialMoveTrash", qsTr("Enable the Move Spam to Trash checkbox if you want to move the spam messages to your web server's Trash folder instead of immediately permanently deleting it."), "file:///usr/share/icons/bb_action_delete.png" ) ) {}
        else if ( persist.tutorial("tutorialOptimize", qsTr("Use the Optimize option from the menu every once in a while if you want to speed up the performance of the app."), "asset:///images/menu/ic_optimize.png" ) ) {}
        else if ( persist.tutorial("tutorialBackupRestore", qsTr("You can use the 'Backup' action at the bottom if you want to save your blocked senders, logs, and keywords. At a later date you can use the Restore action to reimport the backup file to restore your database!"), "asset:///images/menu/ic_backup.png" ) ) {}
    }
}