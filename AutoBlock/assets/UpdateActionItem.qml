import bb.cascades 1.2
import bb.system 1.0

ActionItem
{
    id: updateAction
    title: qsTr("Update") + Retranslate.onLanguageChanged
    property variant progress
    signal confirmed()
    
    onConfirmed: {
        progress = progressDialog.createObject();
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
        
        if (blocked.length > 0) {
            persist.showToast( qsTr("The following keywords were added: %1").arg( blocked.join(", ") ), "", "asset:///images/ic_add_spammer.png" );
        } else {
            persist.showToast( qsTr("The keywords could not be added: %1").arg( addresses.join(", ") ), "", "asset:///images/tabs/ic_blocked.png" );
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
            body: qsTr("The update may consume data. Make sure you are on an appropriate Wi-Fi connection or a good data plan. Would you like to proceed?") + Retranslate.onLanguageChanged
            confirmButton.label: qsTr("Yes") + Retranslate.onLanguageChanged
            cancelButton.label: qsTr("No") + Retranslate.onLanguageChanged
            
            onFinished: {
                console.log("UserEvent: SyncUpdatePrompt", result);
                
                if (result == SystemUiResult.ConfirmButtonSelection)
                {
                    persist.saveValueFor("updateTutorial", 1);
                    updateAction.enabled = false;
                    confirmed();
                }
            }
        },
        
        ComponentDefinition {
            id: progressDialog
            source: "ProgressDialog.qml"
        }
    ]
}