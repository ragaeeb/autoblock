import bb.cascades 1.0
import bb.system 1.2

QtObject
{
    id: promptObject
    
    onCreationCompleted: {
        testPrompt.reset();
    }
    
    property variant testPrompt: SystemPrompt
    {
        id: prompt
        property string address
        property string subject
        cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
        confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
        
        function reset()
        {
            body = qsTr("Please enter the address of the sender to test:");
            address = "";
            subject = "";
            inputField.emptyText = qsTr("abc@hotmail.com or +1234567890");
            inputField.inputMode = SystemUiInputMode.Email;
            inputOptions = SystemUiInputOption.None;
            title = qsTr("Enter address");
        }
        
        onFinished: {
            if (value == SystemUiResult.ConfirmButtonSelection)
            {
                var bookmarkName = inputFieldTextEntry().trim();
                
                if (bookmarkName.length == 0) {
                    toaster.init( qsTr("Invalid input entered"), "images/menu/ic_unblock_all.png" );
                } else if (address.length == 0) { // need to ask for subject now
                    address = bookmarkName;
                    body = qsTr("Please enter the message subject/body:");
                    inputField.emptyText = qsTr("Enter message");
                    inputField.defaultText = "";
                    inputField.inputMode = SystemUiInputMode.Default;
                    inputOptions = SystemUiInputOption.AutoCapitalize;
                    title = qsTr("Enter Subject/Message");
                    show();
                } else if (subject.length == 0) { // need to ask for sender name now
                    subject = bookmarkName;
                    body = qsTr("Please enter the sender name:");
                    inputField.emptyText = qsTr("Enter name");
                    inputField.defaultText = address;
                    inputField.inputMode = SystemUiInputMode.Default;
                    inputOptions = SystemUiInputOption.AutoCapitalize;
                    title = qsTr("Enter Name");
                    show();
                } else { // both fields have been entered
                    var senderName = inputFieldTextEntry().trim();
                    
                    reporter.record( "TestingSender", address+", "+senderName, subject );
                    app.invokeService(address, senderName, subject);
                    persist.showToast( qsTr("Testing...\naddress: %1\nsenderName: %2\nsubject: %3").arg(address).arg(senderName).arg(subject), "images/menu/ic_test.png" );
                    reset();
                }
            }
        }
    }
}