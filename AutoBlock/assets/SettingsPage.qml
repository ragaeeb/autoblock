import bb.cascades 1.0
import bb.cascades.pickers 1.0
import com.canadainc.data 1.0

Page
{
    titleBar: TitleBar {
        title: qsTr("Settings") + Retranslate.onLanguageChanged
    }
    
    actions: [
        ActionItem
        {
            title: qsTr("Backup") + Retranslate.onLanguageChanged
            ActionBar.placement: ActionBarPlacement.OnBar
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
}