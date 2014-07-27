import bb.cascades 1.0
import bb.system 1.2
import com.canadainc.data 1.0

NavigationPane
{
    id: navigationPane
    
    onPopTransitionEnded: {
        page.destroy();
    }
    
    function validatePurchase(control)
    {
        if ( control.checked && !persist.contains("autoblock_constraints") ) {
            persist.showBlockingToast( qsTr("This is a purchasable feature that will also scan the sender's name and email address to try to match if any of the keywords here are found."), qsTr("OK"), "asset:///images/tabs/ic_keywords.png" );
            control.checked = false;
            payment.requestPurchase("autoblock_constraints", "Additional Constraints");
        }
    }
    
    Page
    {
        id: root
        actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
        
        titleBar: TitleBar
        {
            id: titleControl
            kind: TitleBarKind.FreeForm
            scrollBehavior: TitleBarScrollBehavior.NonSticky
            kindProperties: FreeFormTitleBarKindProperties
            {
                Container
                {
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Fill
                    topPadding: 10; bottomPadding: 20; leftPadding: 10
                    
                    Label {
                        id: thresholdLabel
                        verticalAlignment: VerticalAlignment.Center
                        textStyle.base: SystemDefaults.TextStyles.BigText
                    }
                }
                
                expandableArea
                {
                    expanded: true
                    
                    content: Container
                    {
                        horizontalAlignment: HorizontalAlignment.Fill
                        verticalAlignment: VerticalAlignment.Fill
                        leftPadding: 10; rightPadding: 10; topPadding: 5; bottomPadding: 10
                        
                        Slider {
                            value: persist.getValueFor("keywordThreshold")
                            horizontalAlignment: HorizontalAlignment.Fill
                            fromValue: 1
                            toValue: 5
                            
                            onValueChanged: {
                                var actualValue = Math.floor(value);
                                var changed = persist.saveValueFor("keywordThreshold", actualValue, false);
                                thresholdLabel.text = qsTr("Threshold: %1").arg(actualValue);
                            }
                        }
                        
                        PersistCheckBox
                        {
                            id: scanName
                            key: "scanName"
                            text: qsTr("Scan Sender Name") + Retranslate.onLanguageChanged
                            
                            onCheckedChanged: {
                                validatePurchase(scanName);
                            }
                        }
                        
                        PersistCheckBox
                        {
                            id: scanAddress
                            key: "scanAddress"
                            text: qsTr("Scan Sender Address") + Retranslate.onLanguageChanged
                            
                            onCheckedChanged: {
                                validatePurchase(scanAddress);
                                
                                if ( control.checked && persist.tutorial( "tutorialScanAddress", qsTr("Warning: Be very careful when turning on this feature as it can result in harmless messages being classified as spam. For example if you enter a keyword as 'gmail', then any email address that contains 'gmail' will be blocked! This is useful for blocking entire domain names but it can also be too aggressive if not used properly."), "asset:///images/ic_pim_warning.png" ) ) {}
                            }
                        }
                    }
                }
            }
        }
        
        actions: [
            ActionItem {
                id: addAction
                title: qsTr("Add") + Retranslate.onLanguageChanged
                imageSource: "images/menu/ic_add_spammer.png"
                ActionBar.placement: 'Signature' in ActionBarPlacement ? ActionBarPlacement["Signature"] : ActionBarPlacement.OnBar
                
                shortcuts: [
                    SystemShortcut {
                        type: SystemShortcuts.CreateNew
                    }
                ]
                
                onTriggered: {
                    console.log("UserEvent: AddBlockedKeyword");
                    addPrompt.show();
                }
                
                attachedObjects: [
                    SystemPrompt {
                        id: addPrompt
                        title: qsTr("Add Keyword") + Retranslate.onLanguageChanged
                        body: qsTr("Enter the keyword you wish to add (no spaces):") + Retranslate.onLanguageChanged
                        confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                        cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                        inputOptions: SystemUiInputOption.None
                        
                        onFinished: {
                            console.log("UserEvent: AddKeywordPrompt", result);
                            
                            if (result == SystemUiResult.ConfirmButtonSelection)
                            {
                                var value = addPrompt.inputFieldTextEntry().trim().toLowerCase();
                                
                                if ( value.indexOf(" ") >= 0 ) {
                                    persist.showToast( qsTr("The keyword cannot contain any spaces!"), "", "asset:///images/ic_block.png" );
                                    return;
                                } else if (value.length < 4 || value.length > 20) {
                                    persist.showToast( qsTr("The keyword must be between 4 to 20 characters in length (inclusive)!"), "", "asset:///images/ic_block.png" );
                                    return;
                                }
                                
                                var keywordsList = helper.blockKeywords([value]);
                                
                                if (keywordsList.length > 0) {
                                    persist.showToast( qsTr("The following keywords were added: %1").arg( keywordsList.join(", ") ), "", "asset:///images/tabs/ic_keywords.png" );
                                } else {
                                    persist.showToast( qsTr("The keyword could not be blocked: %1").arg(value), "", "asset:///images/ic_block.png" );
                                }
                            }
                        }
                    }
                ]
            },
            
            SearchActionItem {
                imageSource: "images/menu/ic_search_keyword.png"
                
                onQueryChanged: {
                    helper.fetchAllBlockedKeywords(query);
                }
            },
            
            DeleteActionItem {
                id: unblockAllAction
                title: qsTr("Clear All") + Retranslate.onLanguageChanged
                imageSource: "images/menu/ic_unblock_all.png"
                
                onTriggered: {
                    console.log("UserEvent: ClearAllBlockedKeywords");
                    prompt.show();
                }
                
                attachedObjects: [
                    SystemDialog {
                        id: prompt
                        title: qsTr("Confirmation") + Retranslate.onLanguageChanged
                        body: qsTr("Are you sure you want to clear all blocked keywords?") + Retranslate.onLanguageChanged
                        confirmButton.label: qsTr("Yes") + Retranslate.onLanguageChanged
                        cancelButton.label: qsTr("No") + Retranslate.onLanguageChanged
                        
                        onFinished: {
                            console.log("UserEvent: ClearAllBlockedPrompt", result);
                            
                            if (result == SystemUiResult.ConfirmButtonSelection)
                            {
                                helper.clearBlockedKeywords();
                                persist.showToast( qsTr("Cleared all blocked keywords!"), "", "asset:///images/menu/ic_clear.png" );
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
                graphic: "images/empty/ic_empty_keywords.png"
                labelText: qsTr("You have no blocked keywords. Either input them after blocking existing messages, or tap here to add one.")
                
                onImageTapped: {
                    console.log("UserEvent: BlockedKeywordEmptyTapped");
                    addPrompt.show();
                }
            }
            
            ListView
            {
                id: listView
                
                dataModel: GroupDataModel
                {
                    id: adm
                    grouping: ItemGrouping.ByFirstChar
                    sortingKeys: ["term"]
                }
                
                function unblock(blocked)
                {
                	var keywordsList = helper.unblockKeywords(blocked);
                	
                	if (keywordsList.length > 0) {
                        persist.showToast( qsTr("The following keywords were unblocked: %1").arg( keywordsList.join(", ") ), "", "asset:///images/menu/ic_unblock.png" );
                	} else {
                        persist.showToast( qsTr("The following keywords could not be unblocked: %1").arg( blocked.join(", ") ), "", "asset:///images/tabs/ic_blocked.png" );
                	}
                }
                
                multiSelectAction: MultiSelectActionItem {
                    imageSource: "images/menu/ic_select_more.png"
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
                        
                        StandardListItem {
                            id: sli
                            title: ListItemData.term
                            status: ListItemData.count
                            imageSource: "images/tabs/ic_blocked.png"
                            opacity: 0
                            
                            animations: [
                                FadeTransition {
                                    id: slider
                                    fromOpacity: 0
                                    toOpacity: 1
                                    easingCurve: StockCurve.SineOut
                                    duration: 750
                                    delay: Math.min(sli.ListItem.indexInSection * 100, 750)
                                }
                            ]
                            
                            ListItem.onInitializedChanged: {
                                if (initialized) {
                                    slider.play();
                                }
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
                                            console.log("UserEvent: UnblockKeyword");
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
                                console.log("UserEvent: MultiUnblock");
                                var selected = listView.selectionList();
                                var blocked = [];
                                
                                for (var i = selected.length-1; i >= 0; i--) {
                                    blocked.push( adm.data(selected[i]) );
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
                    multiSelectHandler.status = qsTr("%n keywords to unblock", "", n);
                }
                
                function onDataLoaded(id, data)
                {
                    if (id == QueryId.FetchBlockedKeywords)
                    {
                        adm.clear();
                        adm.insertList(data);
                        
                        listView.visible = data.length > 0;
                        emptyDelegate.delegateActive = data.length == 0;
                        
                        if ( persist.tutorial("tutorialKeywords", qsTr("You can add keywords here that can be used to detect whether an unlisted message is spam. The words from message bodies and subjects will be inspected and if they are above the threshold then the message will automatically be treated as spam. For example, a threshold value of 3 means that if more than 3 keywords get detected in a subject or body, it will be considered spam."), "asset:///images/tabs/ic_keywords.png" ) ) {}
                        else if ( persist.tutorial("tutorialScanSenderName", qsTr("Enable the 'Scan Sender Name' checkbox to match keywords on the sender's name as well as the subject line."), "file:///usr/share/icons/bb_action_markspam.png" ) ) {}
                        else if ( persist.tutorial("tutorialScanSenderAddress", qsTr("Enable the 'Scan Sender Address' checkbox to match keywords on the sender's address as well as the subject line. This is especially useful if you want to block domain names for example."), "file:///usr/share/icons/ca_set_as_contact_ringtone.png" ) ) {}
                        else if ( adm.size() > 15 && persist.tutorial("tutorialSearchKeyword", qsTr("You can use the 'Search' action from the menu to search if a specific keyword is in your blocked list."), "asset:///images/menu/ic_search_keyword.png" ) ) {}
                        else if ( persist.tutorial("tutorialAddKeyword", qsTr("Use the 'Add' action from the menu to add a specific keyword you want to block."), "asset:///images/menu/ic_add_spammer.png" ) ) {}
                        else if ( persist.tutorial("tutorialClearBlockedKeywords", qsTr("You can clear this blocked list by selecting 'Clear All' from the menu."), "asset:///images/menu/ic_unblock_all.png" ) ) {}
                        else if ( persist.tutorial("tutorialUnblockKeyword", qsTr("You can unblock a keyword you blocked by mistake by simply pressing-and-holding on the keyword and choosing 'Unblock' from the menu."), "asset:///images/menu/ic_unblock.png" ) ) {}
                    }
                }
                
                onCreationCompleted: {
                    helper.dataReady.connect(onDataLoaded);
                    helper.fetchAllBlockedKeywords();
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
}