import bb.cascades 1.0

NavigationPane
{
    id: navigationPane
    
    onPopTransitionEnded: {
        page.destroy();
    }
    
    Page
    {
        id: conversationsPage
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
                        leftPadding: 10; rightPadding: 10; topPadding: 5

                        AccountsDropDown
                        {
                            id: accountChoice
                            controller: offloader
                            selectedAccountId: persist.getValueFor("accountId")

                            onAccountsLoaded: {
                                if (numAccounts == 0) {
                                    tutorialToast.init( qsTr("Did not find any accounts. Maybe the app does not have the permissions it needs..."), "images/ic_account.png" );
                                } else if (selectedOption == null) {
                                    expanded = true;
                                }
                            }
                            
                            onSelectedOptionChanged: {
                                var value = selectedOption.value;
                                var changed = persist.saveValueFor("accountId", value, false);
                                
                                if (changed) {
                                    console.log("UserEvent: AccountDropDownChanged", value);
                                }
                                
                                offloader.loadMessages(value, selectedOption.isCellular);
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
                                        accountChoice.selectedOptionChanged(accountChoice.selectedOption);
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
                        offloader.loadProgress.connect(onProgressChanged);
                    }
                }
                
                ListView
                {
                    id: listView
                    property variant localizer: offloader
                    
                    layoutProperties: StackLayoutProperties {
                        spaceQuota: 1
                    }
                    
                    multiSelectAction: MultiSelectActionItem {
                        imageSource: "images/menu/ic_select_more.png"
                    }
                    
                    function doBlock(toBlock)
                    {
                        var numbersList = helper.block(toBlock);
                        keywordsDelegate.toBlock = toBlock;
                        
                        var body;
                        
                        if (numbersList.length > 0) {
                            body = qsTr("The following addresses were blocked: %1").arg( numbersList.join(", ") );
                        } else {
                            body = qsTr("The senders could not be blocked. This most likely means the spammers sent the message anonimously. In this case you will have to block by keywords instead. If this is not the case, we suggest filing a bug-report!")
                        }

                        tutorialToast.init(body, "images/menu/ic_blocked_user.png");
                        keywordsDelegate.delegateActive = accountChoice.selectedValue != 8;
                    }
                    
                    function itemType(data, indexPath)
                    {
                        if (data.aid == 23) {
                            return "sms";
                        } else if (data.aid == 8) {
                            return "cellular";
                        } else if (data.aid == 199) {
                            return "pin";
                        } else {
                            return "email";
                        }
                    }
                    
                    listItemComponents: [
                        ListItemComponent
                        {
                            type: "cellular"
                            
                            ConversationListItem
                            {
                                description: qsTr("%n seconds", "", ListItemData.duration)
                                imageSource: "images/ic_call.png"
                                title: ListItemData.senderAddress.length > 0 ? ListItemData.senderAddress : qsTr("Unknown Number") + Retranslate.onLanguageChanged
                            }
                        },
                        
                        ListItemComponent
                        {
                            type: "email"
                            
                            ConversationListItem
                            {
                                imageSource: ListItemData.imageSource ? ListItemData.imageSource : "images/ic_email.png"
                                description: ListItemData.subject ? ListItemData.subject : ListItemData.text.replace(/\n/g, " ").substr(0, 60) + "..."
                            }
                        },
                        
                        ListItemComponent
                        {
                            type: "pin"
                            
                            ConversationListItem
                            {
                                imageSource: "images/ic_user.png"
                                description: ListItemData.text.replace(/\n/g, " ").substr(0, 60) + "..."
                            }
                        },
                        
                        ListItemComponent
                        {
                            type: "sms"
                            
                            ConversationListItem
                            {
                                description: ListItemData.text.replace(/\n/g, " ").substr(0, 60) + "..."
                                imageSource: "images/dropdown/ic_sms.png"
                            }
                        }
                    ]
                    
                    onTriggered: {
                        console.log("UserEvent: ConversationPane ListItem Tapped", indexPath);

                        if ( dataModel.data(indexPath).senderAddress.length > 0 )
                        {
                            multiSelectHandler.active = true;
                            toggleSelection(indexPath);
                        }
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
                                    
                                    mainContainer.visible = !dm.isEmpty();
                                    emptyDelegate.delegateActive = !mainContainer.visible;
                                }
                            }
                        ]
                        
                        status: qsTr("None selected") + Retranslate.onLanguageChanged
                    }
                    
                    onSelectionChanged: {
                        if ( dataModel.data(indexPath).senderAddress.length == 0 && selected ) {
                            select(indexPath, false);
                        }

                        var n = selectionList().length;
                        blockAction.enabled = n > 0;
                        multiSelectHandler.status = qsTr("%1 conversations to mark as spam").arg(n);
                    }
                    
                    onCreationCompleted: {
                        offloader.messagesImported.connect(onMessagesImported);
                    }
                    
                    function onMessagesImported(results)
                    {
                        dm.clear();
                        
                        if (results.length > 0)
                        {
                            dm.append(results);
                            
                            if ( tutorialToast.tutorial("tutorialMarkSpam", qsTr("You can add keywords here that can be used to detect whether an unlisted message is spam. The words from message bodies and subjects will be inspected and if they are above the threshold then the message will automatically be treated as spam. For example, a threshold value of 3 means that if more than 3 keywords get detected in a subject or body, it will be considered spam."), "images/tabs/ic_keywords.png" ) ) {}
                        }
                        
                        multiSelectHandler.status = qsTr("None selected");
                        blockAction.enabled = false;
                        mainContainer.visible = results.length > 0;
                        emptyDelegate.delegateActive = results.length == 0;
                        listView.multiSelectHandler.active = false;
                    }
                }
            }
            
            ControlDelegate
            {
                id: keywordsDelegate
                delegateActive: false
                horizontalAlignment: HorizontalAlignment.Right
                verticalAlignment: VerticalAlignment.Center
                property variant toBlock
                
                sourceComponent: ComponentDefinition
                {
                    Container
                    {
                        horizontalAlignment: HorizontalAlignment.Right
                        verticalAlignment: VerticalAlignment.Center
                        layout: DockLayout {}
                        translationX: 300
                        
                        onCreationCompleted: {
                            tt.play();
                        }
                        
                        animations: [
                            TranslateTransition {
                                id: tt
                                fromX: 300
                                toX: 0
                                duration: 800
                                easingCurve: StockCurve.BounceOut
                                
                                onEnded: {
                                    ttOut.play();
                                }
                            },
                            
                            TranslateTransition
                            {
                                id: ttOut
                                fromX: 0
                                toX: 300
                                easingCurve: StockCurve.QuadraticIn
                                duration: 800
                                delay: 2500
                                
                                onEnded: {
                                    keywordsDelegate.delegateActive = false;
                                }
                            }
                        ]
                        
                        ImageView
                        {
                            horizontalAlignment: HorizontalAlignment.Fill
                            verticalAlignment: VerticalAlignment.Fill
                            imageSource: "images/add_keyword_strip.amd"
                        }
                        
                        Container
                        {
                            leftPadding: 35
                            verticalAlignment: VerticalAlignment.Center
                            
                            ImageView {
                                imageSource: "images/menu/ic_add_spammer.png"
                                verticalAlignment: VerticalAlignment.Center
                            }
                        }
                        
                        Container
                        {
                            leftPadding: 140; topPadding: 36
                            opacity: 0.9
                            
                            Label {
                                text: qsTr("Add") + Retranslate.onLanguageChanged
                                textStyle.fontWeight: FontWeight.Bold
                                textStyle.color: Color.White
                                textStyle.fontSize: FontSize.PointValue
                                textStyle.fontSizeValue: 4
                            }
                            
                            Label {
                                text: qsTr("Keywords") + Retranslate.onLanguageChanged
                                textStyle.fontWeight: FontWeight.Bold
                                textStyle.color: Color.White
                                textStyle.fontSize: FontSize.PointValue
                                textStyle.fontSizeValue: 4
                            }
                        }
                        
                        gestureHandlers: [
                            TapHandler {
                                id: tapHandler
                                property bool launched: false
                                
                                onTapped: {
                                    console.log("UserEvent: AddKeywordsToast");
                                    
                                    if (!launched) {
                                        launched = true;
                                        app.keywordsExtracted.connect(onKeywordsExtracted);
                                        app.extractKeywords(keywordsDelegate.toBlock);
                                    }
                                }
                            }
                        ]
                    }
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
    
    function onKeywordsSelected(keywords)
    {
        var keywordsList = helper.blockKeywords(keywords);
        navigationPane.pop();
        
        if (keywordsList.length > 0) {
            tutorialToast.init( qsTr("The following keywords were added: %1").arg( keywordsList.join(", ") ), "images/tabs/ic_keywords.png" );
        } else {
            tutorialToast.init( qsTr("The keyword could not be blocked: %1").arg(value), "images/ic_block.png" );
        }
    }
    
    function onKeywordsExtracted(keywords)
    {
        app.keywordsExtracted.disconnect(onKeywordsExtracted);
        
        if (keywords.length > 0)
        {
            var inspectPage = definition.createObject();
            inspectPage.elementsSelected.connect(onKeywordsSelected);
            inspectPage.elements = keywords;
            
            navigationPane.push(inspectPage);
        } else {
            tutorialToast.init( qsTr("Could not find any suspicious keywords in the message..."), "images/ic_steps.png" );
        }
    }
    
    attachedObjects: [
        ComponentDefinition {
            id: definition
            source: "ElementPickerPage.qml"
        },
        
        ActionItem {
            id: testKeywords
            imageSource: "images/menu/ic_help.png"
            title: qsTr("Test Keywords") + Retranslate.onLanguageChanged
            ActionBar.placement: ActionBarPlacement.OnBar
            
            onTriggered: {
                console.log("UserEvent: TestKeywordsTriggered");
                
                if (accountChoice.selectedValue != 8)
                {
                    var selected = listView.selectionList();
                    var toBlock = [];
                    
                    for (var i = selected.length-1; i >= 0; i--) {
                        toBlock.push( dm.data(selected[i]) );
                    }
                    
                    app.keywordsExtracted.connect(onKeywordsExtracted);
                    app.extractKeywords(toBlock);
                }
            }
            
            onCreationCompleted: {
                if (reporter.isAdmin) {
                    listView.multiSelectHandler.addAction(testKeywords);
                }
            }
        },
        
        ActionItem
        {
            id: insertRandom
            title: qsTr("Insert Random") + Retranslate.onLanguageChanged
            ActionBar.placement: 'Signature' in ActionBarPlacement ? ActionBarPlacement["Signature"] : ActionBarPlacement.OnBar
            
            onTriggered: {
                console.log("UserEvent: InsertRandom");
                
                dm.clear();
                var elements = [];
                
                for (var i = 0; i < 35; i++) {
                    elements.push( {'sender': Math.random().toString(36).substring(7), 'senderAddress': Math.random().toString(36).substring(5)+"@gmail.com", 'subject': Math.random().toString(36).substring(7), 'time': new Date() } );
                }

                dm.append(elements);
            }
            
            onCreationCompleted: {
                if (reporter.isAdmin) {
                    conversationsPage.addAction(insertRandom);
                }
            }
        }
    ]
}