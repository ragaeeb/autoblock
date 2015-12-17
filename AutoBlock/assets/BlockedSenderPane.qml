import bb.cascades 1.0
import bb.system 1.2
import com.canadainc.data 1.0

NavigationPane
{
    id: navigationPane
    signal addClicked();
    
    onPopTransitionEnded: {
        deviceUtils.cleanUpAndDestroy(page);
    }
    
    Page
    {
        id: root
        
        titleBar: TitleBar
        {
            title: qsTr("Blocked Senders") + Retranslate.onLanguageChanged
            
            acceptAction: UpdateActionItem
            {
                id: uai
                
                onConfirmed: {
                    updater.submit();
                }
            }
        }
        
        onActionMenuVisualStateChanged: {
            if (actionMenuVisualState == ActionMenuVisualState.VisibleFull)
            {
                tutorial.execOverFlow("addSender", qsTr("Use the '%1' action from the menu to add a specific phone number or email address you want to block."), addAction );
                tutorial.execOverFlow("searchSender", qsTr("You can use the '%1' action from the menu to search if a specific sender's address is in your blocked list."), searchAction );
                tutorial.execOverFlow("clearBlocked", qsTr("You can clear all the elements in this blocked list by selecting '%1' from the menu."), unblockAllAction );
            }
        }
        
        actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
        
        actions: [
            ActionItem
            {
                id: addAction
                title: qsTr("Add") + Retranslate.onLanguageChanged
                imageSource: "images/menu/ic_add_email.png"
                ActionBar.placement: ActionBarPlacement.OnBar
                
                onTriggered: {
                    console.log("UserEvent: BlockSenderTriggered");
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
                        inputOptions: SystemUiInputOption.None
                        title: qsTr("Address") + Retranslate.onLanguageChanged
                        
                        onFinished: {
                            console.log("UserEvent: BlockSenderPrompt", value);
                            
                            if (value == SystemUiResult.ConfirmButtonSelection)
                            {
                                var inputEntry = addPrompt.inputFieldTextEntry().trim();
                                var validEmail = ciu.isValidEmail(inputEntry);
                                var validNumber = ciu.isValidPhoneNumber(inputEntry);
                                
                                if (validEmail || validNumber)
                                {
                                    var toBlock = [{'senderAddress': inputEntry, 'address': inputEntry, 'count': 0}];
                                    var blocked = helper.block(navigationPane, toBlock);
                                    
                                    if (blocked.length == 0) {
                                        toaster.init( qsTr("Could not block: %1\n\nPlease file a bug report!").arg(inputEntry), "images/tabs/ic_blocked.png" );
                                    } else {
                                        gdm.insertList(toBlock);
                                        refresh();
                                    }
                                } else {
                                    toaster.init( qsTr("Invalid address entered: %1").arg(inputEntry), "images/menu/ic_keyword.png" );
                                }
                            }
                            
                            tutorial.execCentered( "manualAdd", qsTr("Important: If you are manually attempting to input phone numbers to block note that plus signs and dashes may be necessary in order to match the format that is used by the spammer. It might be more appropriate for you to go to the 'Conversations' tab and add the spammer from there instead."), "images/common/ic_help.png" );
                        }
                    },
                    
                    CanadaIncUtils {
                        id: ciu
                    }
                ]
            },
            
            SearchActionItem
            {
                id: searchAction
                imageSource: "images/menu/ic_search_user.png"
                
                onQueryChanged: {
                    helper.fetchAllBlockedSenders(navigationPane, query);
                }
            },
            
            DeleteActionItem
            {
                id: unblockAllAction
                enabled: listView.visible
                title: qsTr("Unblock All") + Retranslate.onLanguageChanged
                imageSource: "images/menu/ic_unblock_all.png"
                
                function onFinished(ok)
                {
                    console.log("UserEvent: UnblockAllSendersConfirm", ok);
                    
                    if (ok) {
                        helper.clearBlockedSenders(navigationPane);
                    }
                }
                
                onTriggered: {
                    console.log("UserEvent: UnblockAllSenders");
                    persist.showDialog( unblockAllAction, qsTr("Confirmation"), qsTr("Are you sure you want to clear all blocked members?") );
                }
            }
        ]
        
        Container
        {
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            background: ipd.imagePaint
            
            layout: DockLayout {}
            
            EmptyDelegate
            {
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
                scrollRole: ScrollRole.Main
                
                dataModel: GroupDataModel
                {
                    id: gdm
                    grouping: ItemGrouping.ByFirstChar
                    sortingKeys: ["address"]
                }
                
                function unblock(blocked)
                {
                    var keywordsList = helper.unblock(navigationPane, blocked);
                    
                    if (keywordsList.length == 0) {
                        toaster.init( qsTr("The following addresses could not be unblocked: %1").arg( blocked.join(", ") ), "images/tabs/ic_blocked.png" );
                    } else {
                        for (var i = blocked.length-1; i >= 0; i--) {
                            gdm.remove(blocked[i]);
                        }
                        
                        refresh();
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
                    console.log("UserEvent: BlockedListItemTapped", indexPath);
                    multiSelectHandler.active = true;
                    toggleSelection(indexPath);
                }
                
                multiSelectHandler
                {
                    onActiveChanged: {
                        if (active) {
                            tutorial.execActionBar( "unblockSendersMulti", qsTr("Tap here to remove these senders from the list."), "x" );
                        }
                    }
                    
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
    
    function refresh()
    {
        listView.visible = !gdm.isEmpty();
        emptyDelegate.delegateActive = gdm.isEmpty();

        tutorial.execTitle("tutorialSync", qsTr("You can use the '%1' button at the top-right to sync your block list with our servers to discover new spammers reported by the Auto Block community that you have not discovered yet!").arg(uai.title), "r" );
        tutorial.execActionBar( "moreBlockOptions", qsTr("Tap here for more actions you can take on this page."), "x" );

        if ( !gdm.isEmpty() ) {
            tutorial.execCentered("unblockSenders", qsTr("You can unblock a user you blocked by mistake by simply tapping on the blocked address and choosing '%1' from the menu.").arg(unBlockAction.title) );
        }
    }
    
    function onDataLoaded(id, data)
    {
        if (id == QueryId.FetchBlockedSenders)
        {
            gdm.clear();
            gdm.insertList(data);
            
            refresh();
        } else if (id == QueryId.BlockSenders) {
            persist.showToast( qsTr("Successfully blocked address."), ciu.isValidEmail( addPrompt.inputFieldTextEntry().trim() ) ? "images/menu/ic_add_email.png" : "images/menu/ic_add_sms.png" );
        } else if (id == QueryId.UnblockSenders) {
            persist.showToast( qsTr("Addresses successfully unblocked!"), "images/menu/ic_unblock.png" );
        }
    }
    
    function onRefreshNeeded(type)
    {
        if (type == QueryId.BlockSenders || type == QueryId.UnblockSenders) {
            helper.fetchAllBlockedSenders(navigationPane);
        }
    }
    
    onCreationCompleted: {
        helper.refreshNeeded.connect(onRefreshNeeded);
        onRefreshNeeded(QueryId.BlockSenders);
        
        deviceUtils.attachTopBottomKeys(root, listView);
    }
}