import bb.cascades 1.0
import bb.system 1.2
import com.canadainc.data 1.0

NavigationPane
{
    id: navigationPane
    
    onPopTransitionEnded: {
        deviceUtils.cleanUpAndDestroy(page);
    }
    
    function validatePurchase(control)
    {
        if ( control.checked && !persist.contains("autoblock_constraints") )
        {
            toaster.init( qsTr("This is a purchasable feature that will also scan the sender's name and email address to try to match if any of the keywords here are found."), "images/tabs/ic_keywords.png" );
            control.checked = false;
            payment.requestPurchase( "autoblock_constraints", qsTr("Additional Constraints") );
        }
    }
    
    Page
    {
        id: root
        actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
        
        onActionMenuVisualStateChanged: {
            if (actionMenuVisualState == ActionMenuVisualState.VisibleFull)
            {
                if ( adm.size() > 15 ) {
                    tutorial.execOverFlow( "searchKeyword", qsTr("You can use the '%1' action from the menu to search if a specific keyword is in your blocked list."), searchAction );
                }
                
                tutorial.execOverFlow("addKeyword", qsTr("Use the '%1' action from the menu to add a specific keyword you want to block."), addAction );
                tutorial.execOverFlow("clearBlockedKeywords", qsTr("You can clear this blocked list by selecting '%1' from the menu."), unblockAllAction );
            }
        }
        
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
                        textStyle.color: 'Signature' in ActionBarPlacement ? Color.Black : Color.White
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
                                
                                if (checked) {
                                    tutorial.execCentered( "tutorialScanAddress", qsTr("Warning: Be very careful when turning on this feature as it can result in harmless messages being classified as spam. For example if you enter a keyword as 'gmail', then any email address that contains 'gmail' will be blocked! This is useful for blocking entire domain names but it can also be too aggressive if not used properly."), "images/ic_pim_warning.png" );
                                }
                            }
                        }
                        
                        PersistCheckBox
                        {
                            id: ignorePunc
                            topMargin: 10
                            key: "ignorePunctuation"
                            text: qsTr("Strip Punctuation from Keywords") + Retranslate.onLanguageChanged
                            
                            onCheckedChanged: {
                                if (checked) {
                                    infoText.text = qsTr("Punctuation will be removed from messages before they are tested.");
                                } else {
                                    infoText.text = qsTr("Punctuation will be left as-is when comparing with the blocked list of keywords.");
                                }
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
                    SystemPrompt
                    {
                        id: addPrompt
                        title: qsTr("Add Keyword") + Retranslate.onLanguageChanged
                        body: qsTr("Enter the keyword you wish to add (no spaces):") + Retranslate.onLanguageChanged
                        confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                        cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                        inputOptions: SystemUiInputOption.None
                        
                        onFinished: {
                            console.log("UserEvent: AddKeywordPrompt", value);
                            
                            if (value == SystemUiResult.ConfirmButtonSelection)
                            {
                                var inputValue = addPrompt.inputFieldTextEntry().trim().toLowerCase();
                                
                                if ( inputValue.indexOf(" ") >= 0 ) {
                                    toaster.init( qsTr("The keyword cannot contain any spaces!"), "images/ic_block.png" );
                                    return;
                                } else if (inputValue.length < 3 || inputValue.length > 20) {
                                    toaster.init( qsTr("The keyword must be between 3 to 20 characters in length (inclusive)!"), "images/ic_block.png" );
                                    return;
                                }
                                
                                var keywordsList = helper.blockKeywords(navigationPane, [inputValue]);
                                
                                if (keywordsList.length == 0) {
                                    toaster.init( qsTr("The keyword could not be blocked: %1").arg(inputValue), "images/ic_block.png" );
                                } else {
                                    adm.insert({'term': inputValue, 'count': 0});
                                    refresh();
                                }
                            }
                        }
                    }
                ]
            },
            
            SearchActionItem
            {
                id: searchAction
                imageSource: "images/menu/ic_search_keyword.png"
                
                onQueryChanged: {
                    helper.fetchAllBlockedKeywords(navigationPane, query);
                }
            },
            
            DeleteActionItem
            {
                id: unblockAllAction
                enabled: listView.visible
                title: qsTr("Clear All") + Retranslate.onLanguageChanged
                imageSource: "images/menu/ic_unblock_all.png"
                
                function onFinished(ok)
                {
                    if (ok) {
                        helper.clearBlockedKeywords(navigationPane);
                    }
                }
                
                onTriggered: {
                    console.log("UserEvent: ClearAllBlockedKeywords");
                    persist.showDialog( unblockAllAction, qsTr("Confirmation"), qsTr("Are you sure you want to clear all the keywords?") );
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
                scrollRole: ScrollRole.Main
                
                dataModel: GroupDataModel
                {
                    id: adm
                    grouping: ItemGrouping.ByFirstChar
                    sortingKeys: ["term"]
                }
                
                function unblock(blocked)
                {
                	var keywordsList = helper.unblockKeywords(navigationPane, blocked);
                	
                	if (keywordsList.length == 0) {
                        persist.showToast( qsTr("The following keywords could not be unblocked: %1").arg( blocked.join(", ") ), "images/tabs/ic_blocked.png" );
                	} else {
                	    for (var i = blocked.length-1; i >= 0; i--) {
                	        adm.remove(blocked[i]);
                	    }
                	    
                	    refresh();
                	}
                }
                
                onTriggered: {
                    console.log("UserEvent: KeywordTapped", indexPath);
                    multiSelectHandler.active = true;
                    toggleSelection(indexPath);
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
                        }
                    }
                ]
                
                multiSelectHandler
                {
                    onActiveChanged: {
                        if (active) {
                            tutorial.execActionBar( "unblockKeywords", qsTr("Tap here to remove these keywords from the list."), "x" );
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
        listView.visible = !adm.isEmpty();
        emptyDelegate.delegateActive = adm.isEmpty();
        
        tutorial.execCentered("keywords", qsTr("You can add keywords here that can be used to detect whether an unlisted message is spam. The words from message bodies and subjects will be inspected and if they are above the threshold then the message will automatically be treated as spam. For example, a threshold value of 3 means that if more than 3 keywords get detected in a subject or body, it will be considered spam."), "images/tabs/ic_keywords.png" );
        tutorial.execBelowTitleBar("threshold", qsTr("This threshold slider controls the minimum number of keyword hits that must be matched on a message subject before it is blocked.\n\nTo implement more aggressive blocking, decrease this threshold, to be more lenient and only block when multiple keywords are matched, increase the threshold"), 0, "l", "r");
        tutorial.execBelowTitleBar("scanSenderName", qsTr("Enable the '%1' checkbox to match keywords on the sender's name as well as the subject line.").arg(scanName.text), tutorial.du(5), "r", "images/toast/scan_sender.png" );
        tutorial.execBelowTitleBar("scanSenderAddress", qsTr("Enable the '%1' checkbox to match keywords on the sender's address as well as the subject line. This is especially useful if you want to block domain names for example.").arg(scanAddress.text), tutorial.du(12), "r", "images/toast/scan_address.png" );
        tutorial.execBelowTitleBar("stripPunctuation", qsTr("Enable the '%1' checkbox to match keywords on the sender's address as well as the subject line. This is especially useful if you want to block domain names for example.").arg(ignorePunc.text), tutorial.du(20), "r", "images/toast/scan_address.png" );
        
        if ( !adm.isEmpty() ) {
            tutorial.execCentered("unblockKeyword", qsTr("You can unblock a keyword you blocked by mistake by simply pressing-and-holding on the keyword and choosing 'Unblock' from the menu."), "images/menu/ic_unblock.png" );
        }
    }
    
    function onDataLoaded(id, data)
    {
        if (id == QueryId.FetchBlockedKeywords)
        {
            adm.clear();
            adm.insertList(data);

            refresh();
        } else if (id == QueryId.ClearKeywords) {
            persist.showToast( qsTr("Cleared all blocked keywords!"), "images/menu/ic_clear.png" );

            adm.clear();
            refresh();
        } else if (id == QueryId.UnblockKeywords) {
            persist.showToast( qsTr("Unblocked keywords!"), "images/menu/ic_unblock.png" );
        } else if (id == QueryId.BlockKeywords) {
            persist.showToast( qsTr("Keywords successfully added!"), "images/tabs/ic_keywords.png" );
        }
    }
    
    onCreationCompleted: {
        deviceUtils.attachTopBottomKeys(root, listView);
        helper.fetchAllBlockedKeywords(navigationPane);
    }
}