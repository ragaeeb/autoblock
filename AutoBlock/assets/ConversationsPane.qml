import bb.cascades 1.0
import bb.system 1.0

NavigationPane
{
    id: navigationPane
    
    onPopTransitionEnded: {
        page.destroy();
    }
    
    Page
    {
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
                        id: daysLabel
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

                        AccountsDropDown
                        {
                            id: accountChoice
                            selectedAccountId: persist.getValueFor("accountId")

                            onAccountsLoaded: {
                                if (numAccounts == 0) {
                                    persist.showToast( qsTr("Did not find any accounts. Maybe the app does not have the permissions it needs..."), "", "asset:///images/ic_account.png" );
                                } else if (selectedOption == null) {
                                    expanded = true;
                                }
                            }

                            onSelectedValueChanged: {
                                persist.saveValueFor("accountId", selectedValue);
                                app.loadMessages(selectedValue);
                            }
                        }

                        Slider {
                            value: persist.getValueFor("days")
                            horizontalAlignment: HorizontalAlignment.Fill
                            fromValue: 1
                            toValue: 30
                            
                            onValueChanged: {
                                var actualValue = Math.floor(value);
                                var changed = persist.saveValueFor("days", actualValue);
                                daysLabel.text = qsTr("Days to Fetch: %1").arg(actualValue);
                                
                                if (accountChoice.selectedOption != null)
                                {
                                    if (changed) {
                                        accountChoice.selectedValueChanged(accountChoice.selectedValue);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        Container
        {
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            background: ipd.imagePaint
            
            ProgressDelegate
            {
                onCreationCompleted: {
                    app.loadProgress.connect(onProgressChanged);
                }
            }
            
            EmptyDelegate {
                id: emptyDelegate
                graphic: "images/ic_empty_messages.png"
                labelText: qsTr("There are no incoming messages detected for this account. As soon as the first spam message comes in, open this app, come to this screen and add that message as spam and all future messages from that sender will be blocked and deleted! Or increase the 'Days' slider at the top to fetch more messages.") + Retranslate.onLanguageChanged
                
                onImageTapped: {
                    accountChoice.expanded = true;
                }
            }
            
            ListView
            {
                id: listView
                
                layoutProperties: StackLayoutProperties {
                    spaceQuota: 1
                }
                
                multiSelectAction: MultiSelectActionItem {
                    imageSource: "images/ic_select_more.png"
                }
                
                function doBlock(toBlock)
                {
                    var numbersList = helper.block(toBlock);
                    toast.toBlock = toBlock;
                    toast.body = qsTr("The following addresses were blocked: %1").arg( numbersList.join(", ") );
                    toast.icon = "asset:///images/ic_blocked_user.png";
                    
                    toast.show();
                }
                
                listItemComponents: [
                    ListItemComponent
                    {
                        StandardListItem {
                            id: rootItem
                            imageSource: ListItemData.imageSource ? ListItemData.imageSource : "images/ic_user.png"
                            title: ListItemData.sender
                            description: ListItemData.subject ? ListItemData.subject : ListItemData.text.replace(/\n/g, " ").substr(0, 60) + "..."

                            animations: [
                                FadeTransition {
                                    id: slider
                                    fromOpacity: 0
                                    toOpacity: 1
                                    easingCurve: StockCurve.SineInOut
                                    duration: 400
                                }
                            ]

                            contextActions: [
                                ActionSet {
                                    title: ListItemData.senderAddress
                                    subtitle: ListItemData.replyTo

                                    ActionItem
                                    {
                                        ActionBar.placement: ActionBarPlacement.OnBar
                                        title: qsTr("Block") + Retranslate.onLanguageChanged
                                        imageSource: "images/ic_block.png"

                                        onTriggered: {
                                            rootItem.ListItem.view.doBlock([ListItemData]);
                                        }
                                    }
                                }
                            ]

                            onCreationCompleted: {
                                slider.play()
                            }
                        }
                    }
                ]
                
                onTriggered: {
                    multiSelectHandler.active = true;
                    toggleSelection(indexPath);
                }

                dataModel: ArrayDataModel {
                    id: dm
                }

                multiSelectHandler
                {
                    actions: [
                        ActionItem
                        {
                            id: blockAction
                            title: qsTr("Block") + Retranslate.onLanguageChanged
                            imageSource: "images/ic_block.png"
                            enabled: false
                            
                            onTriggered: {
                                var selected = listView.selectionList();
                                var toBlock = [];

                                for (var i = selected.length-1; i >= 0; i--) {
                                    toBlock.push( dm.data(selected[i]) );
                                }

                                listView.doBlock(toBlock);
                            }
                        }
                    ]

                    status: qsTr("None selected") + Retranslate.onLanguageChanged
                }
                
                onSelectionChanged: {
                    var n = selectionList().length;
                    blockAction.enabled = n > 0;
                    multiSelectHandler.status = qsTr("%1 conversations to mark as spam").arg(n);
                }

                onCreationCompleted: {
                    app.messagesImported.connect(onMessagesImported);
                }

                function onMessagesImported(results)
                {
                    dm.clear();

                    if (results.length > 0)
                    {
                        dm.append(results);

                        if ( !persist.contains("tutorialMarkSpam") )
                        {
                            persist.showBlockingToast( qsTr("Which of the following are spam messages? Choose them and tap the Block action at the bottom and any messages from those senders will be blocked in the future!"), qsTr("OK") );
                            persist.saveValueFor("tutorialMarkSpam", 1);
                        }
                    }
                    
                    listView.visible = listView.multiSelectHandler.active = results.length > 0;
                    emptyDelegate.delegateActive = results.length == 0;
                }
            }

            attachedObjects: [
                ImagePaintDefinition {
                    id: ipd
                    imageSource: "images/background.png"
                },
                
                SystemToast {
                    id: toast
                    button.label: qsTr("Add Keywords") + Retranslate.onLanguageChanged
                    property variant toBlock
                    
                    onFinished: {
                        if (value == SystemUiResult.ButtonSelection) {
                            app.extractKeywords(toBlock);
                        }
                    }
                }
            ]
        }
    }
    
    function onKeywordsSelected(keywords)
    {
        var keywordsList = helper.blockKeywords(keywords);
        navigationPane.pop();

        persist.showToast( qsTr("The following keywords were added: %1").arg( keywordsList.join(", ") ), "", "asset:///images/ic_keywords.png" );
    }
    
    function onKeywordsExtracted(keywords)
    {
        if (keywords.length > 0)
        {
            var inspectPage = definition.createObject();
            inspectPage.elementsSelected.connect(onKeywordsSelected);
            inspectPage.elements = keywords;
            
            navigationPane.push(inspectPage);
        } else {
            persist.showToast( qsTr("Could not find any suspicious keywords in the message..."), "", "asset:///images/ic_steps.png" );
        }
    }
    
    onCreationCompleted: {
        app.keywordsExtracted.connect(onKeywordsExtracted);
    }
    
    attachedObjects: [
        ComponentDefinition {
            id: definition
            source: "ElementPickerPage.qml"
        }
    ]
}