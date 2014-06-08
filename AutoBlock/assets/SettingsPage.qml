import bb.cascades 1.0

Page
{
    titleBar: TitleBar {
        title: qsTr("Settings") + Retranslate.onLanguageChanged
    }
    
    ScrollView
    {
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill
        
        Container
        {
            leftPadding: 20; topPadding: 20; rightPadding: 20; bottomPadding: 20
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            
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