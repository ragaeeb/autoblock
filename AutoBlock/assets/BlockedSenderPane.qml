import bb.cascades 1.0
import bb.system 1.0
import com.canadainc.data 1.0

NavigationPane
{
    id: navigationPane
    signal addClicked();
    
    onPopTransitionEnded: {
        page.destroy();
    }
    
    Page
    {
        id: root
        
        titleBar: TitleBar
        {
            title: qsTr("Blocked Senders") + Retranslate.onLanguageChanged
            
            acceptAction: UpdateActionItem
            {
                onConfirmed: {
                    app.submit(gdm);
                }
            }
        }
        
        actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
        
        actions: [
            ActionItem
            {
                title: qsTr("Block Email Sender") + Retranslate.onLanguageChanged
                imageSource: "images/menu/ic_add_email.png"
                ActionBar.placement: ActionBarPlacement.OnBar
                
                onTriggered: {
                    addPrompt.inputField.inputMode = SystemUiInputMode.Email;
                	addPrompt.body = qsTr("Enter the email address to block:");
                    addPrompt.title = qsTr("Email Address");
                    addPrompt.regex = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
                    addPrompt.show();
                }
                
                shortcuts: [
                    SystemShortcut {
                        type: SystemShortcuts.Edit
                    }
                ]
                
                attachedObjects: [
                    SystemPrompt {
                        id: addPrompt
                        property variant regex
                        confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                        cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                        
                        onFinished: {
                            if (result == SystemUiResult.ConfirmButtonSelection)
                            {
                                var value = addPrompt.inputFieldTextEntry().trim();
                                var valid = regex.test(value);
                                
                                if (valid) {
                                    var toBlock = [{'senderAddress': value}];
                                    var blocked = helper.block(toBlock);
                                    persist.showToast( qsTr("Successfully blocked: %1").arg( blocked.join(", ") ), "", "asset:///images/menu/ic_add_email.png" );
                                } else {
                                    persist.showToast( qsTr("Invalid address entered: %1").arg(value), "", "asset:///images/menu/ic_keyword.png" );
                                }
                            }
                        }
                    }
                ]
            },
            
            ActionItem
            {
                title: qsTr("Block SMS Sender") + Retranslate.onLanguageChanged
                imageSource: "images/menu/ic_add_sms.png"
                
                shortcuts: [
                    SystemShortcut {
                        type: SystemShortcuts.Search
                    }
                ]
                
                onTriggered: {
                    addPrompt.inputField.inputMode = SystemUiInputMode.Phone;
                    addPrompt.body = qsTr("Enter the phone number to block:");
                    addPrompt.title = qsTr("Phone Number");
                    addPrompt.regex = /^(?:(?:\(?(?:00|\+)([1-4]\d\d|[1-9]\d?)\)?)?[\-\.\ \\\/]?)?((?:\(?\d{1,}\)?[\-\.\ \\\/]?){0,})(?:[\-\.\ \\\/]?(?:#|ext\.?|extension|x)[\-\.\ \\\/]?(\d+))?$/i;
                    addPrompt.show();
                }
            },
            
            DeleteActionItem {
                id: unblockAllAction
                title: qsTr("Unblock All") + Retranslate.onLanguageChanged
                imageSource: "images/menu/ic_unblock_all.png"
                
                onTriggered: {
                    prompt.show();
                }
                
                attachedObjects: [
                    SystemDialog {
                        id: prompt
                        title: qsTr("Confirmation") + Retranslate.onLanguageChanged
                        body: qsTr("Are you sure you want to clear all blocked members?") + Retranslate.onLanguageChanged
                        confirmButton.label: qsTr("Yes") + Retranslate.onLanguageChanged
                        cancelButton.label: qsTr("No") + Retranslate.onLanguageChanged
                        
                        onFinished: {
                            if (result == SystemUiResult.ConfirmButtonSelection)
                            {
                                helper.clearBlockedSenders();
                                persist.showToast( qsTr("Cleared all blocked senders!"), "", "asset:///images/menu/ic_unblock_all.png" );
                            }
                        }
                    }
                ]
            }
        ]
        
        Container
        {
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            background: ipd.imagePaint
            
            layout: DockLayout {}
            
            EmptyDelegate {
                id: emptyDelegate
                graphic: "images/empty/ic_empty_blocked.png"
                labelText: qsTr("You have no blocked senders. Either manually add phone numbers and email addresses to block from the overflow menu, or tap here to choose spam messages from your existing conversations.")
                
                onImageTapped: {
                    addClicked();
                }
            }
            
            ListView
            {
                id: listView
                
                dataModel: GroupDataModel
                {
                    id: gdm
                    grouping: ItemGrouping.ByFirstChar
                    sortingKeys: ["address"]
                }
                
                function unblock(blocked)
                {
                    var keywordsList = helper.unblock(blocked);
                    persist.showToast( qsTr("The following addresses were unblocked: %1").arg( keywordsList.join(", ") ), "", "asset:///images/menu/ic_unblock.png" );
                }
                
                multiSelectAction: MultiSelectActionItem {
                    imageSource: "images/menu/ic_select_more.png"
                }
                
                listItemComponents: [
                    ListItemComponent {
                        type: "header"
                        
                        Header {
                            title: ListItemData
                        }
                    },
                    
                    ListItemComponent
                    {
                        type: "item"
                        StandardListItem
                        {
                            id: sli
                            title: ListItemData.address
                            status: ListItemData.count
                            description: qsTr("Blocked!") + Retranslate.onLanguageChanged
                            imageSource: "images/menu/ic_blocked_user.png"
                            opacity: 0
                            
                            animations: [
                                FadeTransition {
                                    id: slider
                                    fromOpacity: 0
                                    toOpacity: 1
                                    easingCurve: StockCurve.SineOut
                                    duration: 1000
                                    delay: Math.min(sli.ListItem.indexInSection * 100, 1000)
                                }
                            ]
                            
                            onCreationCompleted: {
                                slider.play()
                            }
                            
                            contextActions: [
                                ActionSet
                                {
                                    title: sli.title
                                    subtitle: sli.description
                                    
                                    DeleteActionItem
                                    {
                                        imageSource: "images/menu/ic_unblock.png"
                                        title: qsTr("Unblock") + Retranslate.onLanguageChanged
                                        
                                        onTriggered: {
                                            sli.ListItem.view.unblock([ListItemData]);
                                        }
                                    }
                                }
                            ]
                        }
                    }
                ]
                
                multiSelectHandler
                {
                    actions: [
                        DeleteActionItem 
                        {
                            id: unBlockAction
                            title: qsTr("Unblock") + Retranslate.onLanguageChanged
                            imageSource: "images/menu/ic_unblock.png"
                            enabled: false
                            
                            onTriggered: {
                                var selected = listView.selectionList();
                                var blocked = [];
                                
                                for (var i = selected.length-1; i >= 0; i--) {
                                    blocked.push( gdm.data(selected[i]) );
                                }
                                
                                listView.unblock(blocked);
                            }
                        }
                    ]
                    
                    status: qsTr("None selected") + Retranslate.onLanguageChanged
                }
                
                onSelectionChanged: {
                    var n = selectionList().length;
                    unBlockAction.enabled = n > 0;
                    multiSelectHandler.status = qsTr("%n senders to unblock", "", n);
                }
            }
            
            attachedObjects: [
                ImagePaintDefinition {
                    id: ipd
                    imageSource: "images/background.png"
                }
            ]
        }
    }
    
    function onDataLoaded(id, data)
    {
        if (id == QueryId.FetchBlockedSenders)
        {
            gdm.clear();
            gdm.insertList(data);
            
            listView.visible = data.length > 0;
            emptyDelegate.delegateActive = data.length == 0;
        }
    }
    
    onCreationCompleted: {
        helper.dataReady.connect(onDataLoaded);
        helper.fetchAllBlockedSenders();
    }
}