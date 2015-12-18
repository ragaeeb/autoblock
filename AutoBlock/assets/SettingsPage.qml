import bb.cascades 1.0
import bb.cascades.pickers 1.0
import com.canadainc.data 1.0

Page
{
    id: rootPage
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    
    titleBar: TitleBar {
        title: qsTr("Settings") + Retranslate.onLanguageChanged
    }
    
    function cleanUp()
    {
        updater.backupComplete.disconnect(backup.onSaved);
        updater.restoreComplete.disconnect(restore.onRestored);
    }
    
    onActionMenuVisualStateChanged: {
        if (actionMenuVisualState == ActionMenuVisualState.VisibleFull) {
            tutorial.execOverFlow("recovery", qsTr("You can use the '%1' action from the menu to recreate the database if it became corrupt."), recover );
        }
        
        reporter.record("SettingsPageMenuOpened", actionMenuVisualState.toString());
    }
    
    onCreationCompleted: {
        tutorial.execBelowTitleBar("sound", qsTr("Enable the '%1' checkbox if you want to hear a sound everytime a message is blocked (this will only sound if you have the device is an appropriate profile that allows notifications).").arg(sound.text), 0, "r", undefined, "images/toast/sound.png" );
        //tutorial.execBelowTitleBar("tutorialBlockStrangers", qsTr("Enable the Block Non-Contacts checkbox if you want to block messages from anyone who is not in your contact list."), "file:///usr/share/icons/ic_open_contacts.png" );
        tutorial.execBelowTitleBar("whitelist", qsTr("Enable the '%1' checkbox if you want to prevent scanning of messages sent by anyone in your contact list.").arg(whitelist.text), tutorial.du(3), "r", undefined, "images/toast/whitelist.png" );
        tutorial.execBelowTitleBar("startConversations", qsTr("Enable the '%1' checkbox if you want the app to start at the Conversations tab instead of the default Logs tab.").arg(startConvo.text), tutorial.du(12), "r", undefined, "images/tabs/ic_conversations.png" );
        tutorial.execBelowTitleBar("moveTrash", qsTr("Enable the '%1' checkbox if you want to move the spam messages to your web server's Trash folder instead of immediately permanently deleting it.").arg(moveTrash.text), tutorial.du(25), "r", undefined, "images/toast/move_trash.png" );

        tutorial.execActionBar("optimize", qsTr("Use the '%1' option from the menu every once in a while if you want to speed up the performance of the app.").arg(optimize.title), "r" );
        tutorial.execActionBar("backup", qsTr("You can use the '%1' action at the bottom if you want to save your blocked senders, logs, and keywords.").arg(backup.title) );
        tutorial.execActionBar("restore", qsTr("At a later date you can use the '%1' action to reimport the backup file to restore your database!").arg(restore.title), "l" );
        tutorial.execActionBar("settingsBack", qsTr("To close this page, either swipe to the right or tap on this back button!"), "b" );
        
        reporter.initPage(rootPage);
        updater.backupComplete.connect(backup.onSaved);
        updater.restoreComplete.connect(restore.onRestored);
    }
    
    actions: [
        ActionItem
        {
            id: backup
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
                reporter.record("Backup");
            }
            
            function onSaved(result)
            {
                toaster.init( qsTr("Successfully backed up to %1").arg( result.substring(15) ), "images/menu/ic_backup.png" );
                reporter.record("BackupComplete");
            }
        },
        
        ActionItem
        {
            id: restore
            title: qsTr("Restore") + Retranslate.onLanguageChanged
            ActionBar.placement: ActionBarPlacement.OnBar
            imageSource: "images/menu/ic_restore.png"
            
            onTriggered: {
                console.log("UserEvent: Restore");
                filePicker.title = qsTr("Select File");
                filePicker.mode = FilePickerMode.Picker
                
                filePicker.open();
                reporter.record("Restore");
            }
            
            function onRestored(result)
            {
                if (result) {
                    reporter.record("SuccessfulRestore");
                    app.exitAfterRestore();
                } else {
                    reporter.record("FailedRestore");
                    helper.setActive(true);
                    toaster.init( qsTr("The database could not be restored. Please re-check the backup file to ensure it is valid, and if the problem persists please file a bug report. Make sure to attach the backup file with your report!"), "images/menu/ic_restore_error.png" );
                }
            }
        },
        
        ActionItem
        {
            id: optimize
            imageSource: "images/menu/ic_optimize.png"
            title: qsTr("Optimize") + Retranslate.onLanguageChanged
            ActionBar.placement: ActionBarPlacement.OnBar
            
            onTriggered: {
                console.log("UserEvent: Optimize");
                busy.running = true;
                helper.optimize(optimize);
                reporter.record("Optimize");
            }
            
            function onDataLoaded(id, data)
            {
                if (id == QueryId.Optimize)
                {
                    busy.running = false;
                    toaster.init( qsTr("Optimization Complete!"), "images/menu/ic_optimize.png" );
                }
            }
        },
        
        ActionItem
        {
            id: recover
            imageSource: "images/menu/ic_error_recovery.png"
            title: qsTr("Error Recovery") + Retranslate.onLanguageChanged
            
            onTriggered: {
                console.log("UserEvent: ErrorRecovery");
                app.forceSetup();
                
                toaster.init( qsTr("Error Recovery triggered!"), "images/menu/ic_error_recovery.png" );
                reporter.record("ErrorRecovery");
            }
        }
    ]
    
    attachedObjects: [
        FilePicker {
            id: filePicker
            defaultType: FileType.Other
            filter: ["*.zip"]
            
            directories :  {
                return ["/accounts/1000/removable/sdcard", "/accounts/1000/shared/misc"]
            }
            
            onFileSelected : {
                console.log("UserEvent: FileSelected", selectedFiles[0]);
                
                if (mode == FilePickerMode.Picker) {
                    helper.setActive(false);
                    updater.restore(selectedFiles[0]);
                } else {
                    updater.backup(selectedFiles[0]);
                }
            }
            
            onCanceled: {
                reporter.record("CancelFilePicker");
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
                id: sound
                key: "sound"
                text: qsTr("Sound") + Retranslate.onLanguageChanged
                
                onCheckedChanged: {
                    if (checked) {
                        infoText.text = qsTr("A sound will be played every time a spam message is blocked.");
                    } else {
                        infoText.text = qsTr("No sound will be played every time a spam message is blocked.");
                    }
                }
                
                onValueChanged: {
                    reporter.record( "Sound", checked.toString() );
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
                id: whitelist
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
                
                onValueChanged: {
                    reporter.record( "Whitelist", checked.toString() );
                }
            }
            
            PersistCheckBox
            {
                id: startConvo
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
                
                onValueChanged: {
                    reporter.record( "StartAtConversations", checked.toString() );
                }
            }
            
            CheckBox
            {
                id: moveTrash
                topMargin: 10
                text: qsTr("Move Spam to Trash") + Retranslate.onLanguageChanged
                
                onCheckedChanged: {
                    if ( checked && !persist.contains("autoblock_junk") ) {
                        toaster.init( qsTr("This is a purchasable feature that will allow spam messages to be moved to the trash folder instead of directly deleting them. Press OK to launch the payment screen."), "images/toast/move_trash.png" );
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
            
            ImageView {
                topMargin: 40
                imageSource: "images/divider.png"
                horizontalAlignment: HorizontalAlignment.Center
            }
            
            Label {
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