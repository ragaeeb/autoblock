import bb.cascades 1.2

ActionItem
{
    id: updateAction
    imageSource: "images/dropdown/ic_sync.png"
    title: qsTr("Update") + Retranslate.onLanguageChanged
    property variant progress
    signal confirmed()
    
    onConfirmed: {
        definition.source = "ProgressDialog.qml";
        progress = definition.createObject();
        progress.open();
    }
    
    onTriggered: {
        console.log("UserEvent: SyncUpdate");
        enabled = false;
        
        if ( !persist.contains("updateTutorial") )
        {
            var confirm = persist.showBlockingDialog( qsTr("Confirmation"), qsTr("The update may consume data. Make sure you are on an appropriate Wi-Fi connection or a good data plan. This action will sync your blocked list with our servers so that you can benefit from and benefit other users to report spammers. Would you like to proceed?") );
            console.log("UserEvent: SyncUpdateConfirm", confirm);
            
            if (confirm) {
                persist.saveValueFor("updateTutorial", 1, false);
                updateAction.enabled = false;
                confirmed();
            }
        } else {
            confirmed();
        }
    }
    
    function onSpammersSelected(addresses)
    {
        var transformed = [];
        
        for (var i = addresses.length-1; i >= 0; i--) {
            transformed.push({'senderAddress': addresses[i]});
        }
        
        var blocked = helper.block(transformed);
        navigationPane.pop();
        
        if (blocked.length > 0)
        {
            tutorialToast.init( blocked.length > 50 ? qsTr("Blocking addresses...") : qsTr("The following addresses were added: %1").arg( blocked.join(", ") ), "images/menu/ic_add_spammer.png" );
        } else {
            tutorialToast.init( qsTr("The addresses could not be added: %1\n\nPlease file a bug report!").arg( addresses.join(", ") ), "images/tabs/ic_blocked.png" );
        }
    }
    
    function onUpdatesAvailable(addresses)
    {
        enabled = true;
        
        if (progress) {
            progress.close();
            progress = undefined;
        }
        
        if (addresses.length > 0)
        {
            var inspectPage = updatePicker.createObject();
            inspectPage.elementsSelected.connect(onSpammersSelected);
            inspectPage.elements = addresses;
            
            navigationPane.push(inspectPage);
        } else {
            tutorialToast.init( qsTr("There are no new known spammers available yet.\nCheck back in a few days."), "images/toast/ic_import.png" );
        }
    }
    
    onCreationCompleted: {
        updater.updatesAvailable.connect(onUpdatesAvailable);
    }
    
    attachedObjects: [
        ComponentDefinition
        {
            id: updatePicker
            
            ElementPickerPage {
                titleText: qsTr("Reported Spammers") + Retranslate.onLanguageChanged
                instructionText: qsTr("Which of the following reported spammers do you want to add to your blocked list?") + Retranslate.onLanguageChanged
                listImage: "images/menu/ic_blocked_user.png"
            }
        },
        
        ComponentDefinition {
            id: definition
        }
    ]
}