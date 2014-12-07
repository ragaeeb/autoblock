import bb.cascades 1.2
import bb.system 1.0

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
        
        if ( !persist.contains("updateTutorial") ) {
            prompt.show();
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
            persist.showToast( blocked.length > 50 ? qsTr("Blocking addresses...") : qsTr("The following addresses were added: %1").arg( blocked.join(", ") ), "", "asset:///images/menu/ic_add_spammer.png" );
        } else {
            persist.showToast( qsTr("The addresses could not be added: %1\n\nPlease file a bug report!").arg( addresses.join(", ") ), "", "asset:///images/tabs/ic_blocked.png" );
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
            persist.showToast( qsTr("There are no new known spammers available yet.\nCheck back in a few days."), "", "asset:///images/toast/ic_import.png" );
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
        
        SystemDialog {
            id: prompt
            title: qsTr("Confirmation") + Retranslate.onLanguageChanged
            body: qsTr("The update may consume data. Make sure you are on an appropriate Wi-Fi connection or a good data plan. This action will sync your blocked list with our servers so that you can benefit from and benefit other users to report spammers. Would you like to proceed?") + Retranslate.onLanguageChanged
            confirmButton.label: qsTr("Yes") + Retranslate.onLanguageChanged
            cancelButton.label: qsTr("No") + Retranslate.onLanguageChanged
            
            onFinished: {
                console.log("UserEvent: SyncUpdatePrompt", result);
                
                if (value == SystemUiResult.ConfirmButtonSelection)
                {
                    persist.saveValueFor("updateTutorial", 1, false);
                    updateAction.enabled = false;
                    confirmed();
                }
            }
        },
        
        ComponentDefinition {
            id: definition
        }
    ]
}