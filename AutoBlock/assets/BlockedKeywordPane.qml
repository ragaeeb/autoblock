import bb.cascades 1.0
import bb.system 1.0
import com.canadainc.data 1.0

NavigationPane
{
    id: navigationPane
    
    onPopTransitionEnded: {
        page.destroy();
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
                        textStyle.color: Color.White
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
                        leftPadding: 10; rightPadding: 10; topPadding: 5
                        
                        Slider {
                            value: persist.getValueFor("keywordThreshold")
                            horizontalAlignment: HorizontalAlignment.Fill
                            fromValue: 1
                            toValue: 10
                            
                            onValueChanged: {
                                var actualValue = Math.floor(value);
                                var changed = persist.saveValueFor("keywordThreshold", actualValue);
                                thresholdLabel.text = qsTr("Threshold: %1").arg(actualValue);
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
                imageSource: "images/ic_add_spammer.png"
                ActionBar.placement: ActionBarPlacement.OnBar
                
                shortcuts: [
                    SystemShortcut {
                        type: SystemShortcuts.CreateNew
                    }
                ]
                
                onTriggered: {
                    addPrompt.show();
                }
                
                attachedObjects: [
                    SystemPrompt {
                        id: addPrompt
                        title: qsTr("Add Keyword") + Retranslate.onLanguageChanged
                        body: qsTr("Enter the keyword you wish to add (no spaces):") + Retranslate.onLanguageChanged
                        confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                        cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                        
                        onFinished: {
                            if (result == SystemUiResult.ConfirmButtonSelection)
                            {
                                var value = addPrompt.inputFieldTextEntry().trim().toLowerCase();
                                
                                if ( value.indexOf(" ") == -1 ) {
                                    value = app.validateKeyword(value);
                                    
                                    if (value.length > 0) {
                                        var keywordsList = helper.blockKeywords([value]);
                                        persist.showToast( qsTr("The following keywords were added: %1").arg( keywordsList.join(", ") ), "", "asset:///images/ic_add_spammer.png" );
                                    } else {
                                        persist.showToast( qsTr("Invalid keyword entered (must be between 4-10 characters)."), "", "asset:///images/ic_block.png" );
                                    }
                                } else {
                                    persist.showToast( qsTr("The keyword cannot contain any spaces!"), "", "asset:///images/ic_block.png" );
                                }
                            }
                        }
                    }
                ]
            },
            
            DeleteActionItem {
                id: unblockAllAction
                title: qsTr("Clear All") + Retranslate.onLanguageChanged
                imageSource: "images/ic_unblock_all.png"
                
                onTriggered: {
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
                            if (result == SystemUiResult.ConfirmButtonSelection)
                            {
                                helper.clearBlockedKeywords();
                                persist.showToast( qsTr("Cleared all blocked keywords!"), "", "asset:///images/ic_clear.png" );
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
                    addPrompt.show();
                }
            }
            
            ListView
            {
                id: listView
                
                dataModel: ArrayDataModel {
                    id: adm
                }
                
                function unblock(blocked)
                {
                	var keywordsList = helper.unblockKeywords(blocked);
                    persist.showToast( qsTr("The following keywords were unblocked: %1").arg( keywordsList.join(", ") ), "", "asset:///images/ic_unblock.png" );
                }
                
                multiSelectAction: MultiSelectActionItem {
                    imageSource: "images/ic_select_more.png"
                }
                
                listItemComponents: [
                    ListItemComponent
                    {
                        StandardListItem {
                            id: sli
                            title: ListItemData.term
                            status: ListItemData.count
                            imageSource: "images/ic_blocked.png"
                            opacity: 0
                            
                            animations: [
                                FadeTransition {
                                    id: slider
                                    fromOpacity: 0
                                    toOpacity: 1
                                    easingCurve: StockCurve.SineOut
                                    duration: 1000
                                    delay: sli.ListItem.indexInSection * 100
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
                                        imageSource: "images/ic_unblock.png"
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
                            imageSource: "images/ic_unblock.png"
                            enabled: false
                            
                            onTriggered: {
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
                        adm.append(data);
                        
                        listView.visible = data.length > 0;
                        emptyDelegate.delegateActive = data.length == 0;
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
    
    onCreationCompleted: {
        if ( !persist.contains("tutorialKeywords") )
        {
            persist.showToast( qsTr("You can add keywords here that can be used to detect whether an unlisted message is spam. The words from message bodies and subjects will be inspected and if they are above the threshold then the message will automatically be treated as spam. For example, a threshold value of 3 means that if more than 3 keywords get detected in a subject or body, it will be considered spam."), qsTr("OK"), "asset:///images/ic_keywords.png" );
            persist.saveValueFor("tutorialKeywords", 1);
        }
    }
}