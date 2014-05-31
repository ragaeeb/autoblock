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
                                var changed = persist.saveValueFor("accountId", selectedValue, false);
                                
                                if (changed) {
                                    console.log("UserEvent: AccountDropDownChanged", selectedValue);
                                }
                                
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
                                var changed = persist.saveValueFor("days", actualValue, false);
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
            id: rootContainer
            background: ipd.imagePaint
            layout: DockLayout {}
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            
            EmptyDelegate
            {
                id: emptyDelegate
                graphic: "images/empty/ic_empty_messages.png"
                labelText: qsTr("There are no incoming messages detected for this account. As soon as the first spam message comes in, open this app, come to this screen and add that message as spam and all future messages from that sender will be blocked and deleted! Or increase the 'Days' slider at the top to fetch more messages.") + Retranslate.onLanguageChanged
                
                onImageTapped: {
                    console.log("UserEvent: ConversationsEmptyTapped");
                    accountChoice.expanded = true;
                }
            }
            
            Container
            {
                id: mainContainer
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Fill
                
                ProgressDelegate
                {
                    onCreationCompleted: {
                        app.loadProgress.connect(onProgressChanged);
                    }
                }
                
                ListView
                {
                    id: listView
                    
                    layoutProperties: StackLayoutProperties {
                        spaceQuota: 1
                    }
                    
                    multiSelectAction: MultiSelectActionItem {
                        imageSource: "images/menu/ic_select_more.png"
                    }
                    
                    function doBlock(toBlock)
                    {
                        var numbersList = helper.block(toBlock);
                        toast.toBlock = toBlock;
                        
                        if (numbersList.length > 0) {
                            toast.body = qsTr("The following addresses were blocked: %1").arg( numbersList.join(", ") );
                        } else {
                            toast.body = qsTr("The senders could not be blocked. We suggest filing a bug-report.")
                        }

                        toast.icon = "asset:///images/menu/ic_blocked_user.png";
                        rootContainer.touch.connect(toast.cancel);
                        
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
                                
                                onCreationCompleted: {
                                    slider.play()
                                }
                            }
                        }
                    ]
                    
                    onTriggered: {
                        console.log("UserEvent: ConversationPane ListItem Tapped", indexPath);
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
                                    console.log("UserEvent: MultiBlock");
                                    var selected = listView.selectionList();
                                    var toBlock = [];
                                    
                                    for (var i = selected.length-1; i >= 0; i--) {
                                        toBlock.push( dm.data(selected[i]) );
                                    }
                                    
                                    listView.doBlock(toBlock);
                                    
                                    for (var i = selected.length-1; i >= 0; i--) {
                                        dm.removeAt(selected[i][0]);
                                    }
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
                            
                            if ( persist.tutorial("tutorialMarkSpam", qsTr("You can add keywords here that can be used to detect whether an unlisted message is spam. The words from message bodies and subjects will be inspected and if they are above the threshold then the message will automatically be treated as spam. For example, a threshold value of 3 means that if more than 3 keywords get detected in a subject or body, it will be considered spam."), "asset:///images/ic_keywords.png" ) ) {}
                            else if ( persist.tutorialVideo("http://www.youtube.com/watch?v=rFoFPHxUF34") ) {}
                        }
                        
                        multiSelectHandler.status = qsTr("None selected");
                        blockAction.enabled = false;
                        mainContainer.visible = listView.multiSelectHandler.active = results.length > 0;
                        emptyDelegate.delegateActive = results.length == 0;
                    }
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
                        console.log("UserEvent: AddKeywordsToast", result);
                        
                        if (value == SystemUiResult.ButtonSelection) {
                            app.extractKeywords(toBlock);
                        }
                        
                        rootContainer.touch.disconnect(toast.cancel);
                    }
                }
            ]
        }
    }
    
    function onKeywordsSelected(keywords)
    {
        var keywordsList = helper.blockKeywords(keywords);
        navigationPane.pop();
        
        if (keywordsList.length > 0) {
            persist.showToast( qsTr("The following keywords were added: %1").arg( keywordsList.join(", ") ), "", "asset:///images/ic_keywords.png" );
        } else {
            persist.showToast( qsTr("The keyword could not be blocked: %1").arg(value), "", "asset:///images/ic_block.png" );
        }
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