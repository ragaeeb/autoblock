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
                    updater.submit();
                }
            }
        }
        
        actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
        
        actions: [
            ActionItem
            {
                title: qsTr("Add") + Retranslate.onLanguageChanged
                imageSource: "images/menu/ic_add_email.png"
                ActionBar.placement: ActionBarPlacement.OnBar
                
                onTriggered: {
                    console.log("UserEvent: BlockEmailSender");
                    addPrompt.show();
                }
                
                shortcuts: [
                    SystemShortcut {
                        type: SystemShortcuts.CreateNew
                    }
                ]
                
                attachedObjects: [
                    SystemPrompt {
                        id: addPrompt
                        body: qsTr("Enter the email/phone number to block:") + Retranslate.onLanguageChanged
                        confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                        cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                        inputField.inputMode: SystemUiInputMode.Email
                        inputField.emptyText: qsTr("(ie: +14162150012 OR abc@spam.com") + Retranslate.onLanguageChanged
                        title: qsTr("Address") + Retranslate.onLanguageChanged
                        
                        onFinished: {
                            console.log("UserEvent: BlockSenderPrompt", result);
                            
                            if (result == SystemUiResult.ConfirmButtonSelection)
                            {
                                var emailRegex = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
                                var phoneRegex = /^(?:(?:\(?(?:00|\+)([1-4]\d\d|[1-9]\d?)\)?)?[\-\.\ \\\/]?)?((?:\(?\d{1,}\)?[\-\.\ \\\/]?){0,})(?:[\-\.\ \\\/]?(?:#|ext\.?|extension|x)[\-\.\ \\\/]?(\d+))?$/i;
                                
                                var value = addPrompt.inputFieldTextEntry().trim();
                                var validEmail = emailRegex.test(value);
                                var validNumber = phoneRegex.test(value);
                                
                                if (validEmail || validNumber)
                                {
                                    var toBlock = [{'senderAddress': value}];
                                    var blocked = helper.block(toBlock);
                                    
                                    if (blocked.length > 0) {
                                        persist.showToast( qsTr("Successfully blocked: %1").arg( blocked.join(", ") ), "", validEmail ? "asset:///images/menu/ic_add_email.png" : "asset:///images/menu/ic_add_sms.png" );
                                    } else {
                                        persist.showToast( qsTr("Could not block: %1").arg(value), "", "asset:///images/tabs/ic_blocked.png" );
                                    }
                                } else {
                                    persist.showToast( qsTr("Invalid address entered: %1").arg(value), "", "asset:///images/menu/ic_keyword.png" );
                                }
                            }
                        }
                    }
                ]
            },
            
            SearchActionItem {
                imageSource: "images/menu/ic_search_user.png"
                
                onQueryChanged: {
                    helper.fetchAllBlockedSenders(query);
                }
            },
            
            DeleteActionItem {
                id: unblockAllAction
                title: qsTr("Unblock All") + Retranslate.onLanguageChanged
                imageSource: "images/menu/ic_unblock_all.png"
                
                onTriggered: {
                    console.log("UserEvent: UnblockAllSenders");
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
                            console.log("UserEvent: UnblockAllPrompt", result);
                            
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
                    console.log("UserEvent: BlockedSenderEmptyTapped");
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
                    
                    if (keywordsList.length > 0) {
                        persist.showToast( qsTr("The following addresses were unblocked: %1").arg( keywordsList.join(", ") ), "", "asset:///images/menu/ic_unblock.png" );
                    } else {
                        persist.showToast( qsTr("The following addresses could not be unblocked: %1").arg( blocked.join(", ") ), "", "asset:///images/tabs/ic_blocked.png" );
                    }
                }
                
                listItemComponents: [
                    ListItemComponent {
                        type: "header"
                        
                        Header {
                            title: ListItemData
                            subtitle: ListItem.view.dataModel.childCount(ListItem.indexPath)
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
                                    duration: 700
                                    delay: Math.min(sli.ListItem.indexInSection * 100, 750)
                                }
                            ]
                            
                            ListItem.onInitializedChanged: {
                                if (initialized) {
                                    slider.play();
                                }
                            }
                        }
                    }
                ]
                
                onTriggered: {
                    console.log("UserEvent: BlockedListItem Tapped", indexPath);
                    multiSelectHandler.active = true;
                    toggleSelection(indexPath);
                }
                
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
                                console.log("UserEvent: UnblockMultiSenders");
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
            
            if ( persist.tutorialVideo("http://www.youtube.com/watch?v=rFoFPHxUF34") ) {}
            else if ( persist.tutorial("tutorialSync", qsTr("You can use the 'Update' button at the top-right to sync your block list with our servers to discover new spammers reported by the Auto Block community that you have not discovered yet!"), "asset:///images/toast/ic_import.png" ) ) {}
            else if ( persist.tutorial("tutorialSettings", qsTr("Swipe-down from the top-bezel and choose 'Settings' to customize the app!"), "file:///usr/share/icons/success_checkmark.png" ) ) {}
            else if ( gdm.size() > 15 && persist.tutorial("tutorialSearchSender", qsTr("You can use the 'Search' action from the menu to search if a specific sender's address is in your blocked list."), "asset:///images/menu/ic_search_user.png" ) ) {}
            else if ( persist.tutorial("tutorialAddSender", qsTr("Use the 'Add' action from the menu to add a specific phone number or email address you want to block."), "asset:///images/menu/ic_search_user.png" ) ) {}
            else if ( persist.tutorial("tutorialClearBlocked", qsTr("You can clear this blocked list by selecting 'Unblock All' from the menu."), "asset:///images/menu/ic_unblock_all.png" ) ) {}
            else if ( persist.tutorial("tutorialUnblock", qsTr("You can unblock a user you blocked by mistake by simply tapping on the blocked address and choosing 'Unblock' from the menu."), "asset:///images/menu/ic_unblock.png" ) ) {}
        }
    }
    
    onCreationCompleted: {
        helper.dataReady.connect(onDataLoaded);
        helper.fetchAllBlockedSenders();
    }
}