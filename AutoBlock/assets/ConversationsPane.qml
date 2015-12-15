import bb.cascades 1.0
import com.canadainc.data 1.0

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
        
        titleBar: ConversationTitleBar {
            id: ctb
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
                    reporter.record("ConversationsEmptyTapped");
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
                    scrollRole: ScrollRole.Main
                    
                    layoutProperties: StackLayoutProperties {
                        spaceQuota: 1
                    }
                    
                    multiSelectAction: MultiSelectActionItem {
                        imageSource: "images/menu/ic_select_more.png"
                    }
                    
                    function onDataLoaded(id, data)
                    {
                        if (id == QueryId.BlockSenders) {
                            persist.showToast( qsTr("Addresses successfully blocked!"), "images/menu/ic_blocked_user.png" );
                        } else if (id == QueryId.BlockKeywords) {
                            persist.showToast( qsTr("The keywords were successfully added!"), "images/tabs/ic_keywords.png" );
                        }
                    }
                    
                    function extractKeywords(cookie)
                    {
                        app.keywordsExtracted.connect(onKeywordsExtracted);
                        app.extractKeywords(cookie);
                    }
                    
                    function onFinished(result, rememberMe, cookie)
                    {
                        if (rememberMe) {
                            persist.setFlag("parseKeywords", result ? 1 : -1);
                        }
                        
                        if (result) {
                            extractKeywords(cookie);
                        }
                        
                        reporter.record( "ParseKeywords", result.toString()+"_"+rememberMe.toString() );
                    }
                    
                    function doBlock(toBlock)
                    {
                        var numbersList = helper.block(listView, toBlock);

                        if (numbersList.length == 0) {
                            toaster.init( qsTr("The senders could not be blocked. This most likely means the spammers sent the message anonimously. In this case you will have to block by keywords instead. If this is not the case, we suggest filing a bug-report!"), "images/menu/ic_blocked_user.png" );
                        } else if (ctb.accounts.selectedValue != 8) {
                            var flag = persist.getFlag("parseKeywords");

                            if (flag == 1) { // auto
                                extractKeywords(toBlock);
                            } else if (flag == -1) {
                                // don't parse keywords
                            } else {
                                persist.showDialog( listView, toBlock, qsTr("Keyword Parsing"), qsTr("Would you like to add the keywords found in the message to block by keyword?"), qsTr("Yes"), qsTr("No"), true, qsTr("Don't ask again"), false );
                            }
                        }
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
                                imageSource: "images/list/ic_call.png"
                                title: ListItemData.senderAddress.length > 0 ? ListItemData.senderAddress : qsTr("Unknown Number") + Retranslate.onLanguageChanged
                            }
                        },
                        
                        ListItemComponent
                        {
                            type: "email"
                            
                            ConversationListItem
                            {
                                imageSource: ListItemData.imageSource ? ListItemData.imageSource : "images/list/ic_email.png"
                                description: ListItemData.subject ? ListItemData.subject : ListItemData.text.replace(/\n/g, " ").substr(0, 60) + "..."
                            }
                        },
                        
                        ListItemComponent
                        {
                            type: "pin"
                            
                            ConversationListItem
                            {
                                imageSource: "images/list/ic_user.png"
                                description: ListItemData.text.replace(/\n/g, " ").substr(0, 60) + "..."
                            }
                        },
                        
                        ListItemComponent
                        {
                            type: "sms"
                            
                            ConversationListItem
                            {
                                description: ListItemData.text.replace(/\n/g, " ").substr(0, 60) + "..."
                                imageSource: "images/list/ic_sms.png"
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
                                    reporter.record("Block", toBlock.length);
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
                        dm.append(results);
                        
                        multiSelectHandler.status = qsTr("None selected");
                        blockAction.enabled = false;
                        mainContainer.visible = results.length > 0;
                        emptyDelegate.delegateActive = results.length == 0;
                        listView.multiSelectHandler.active = false;
                        
                        reporter.record("MessagesFound", results.length);
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
        var keywordsList = helper.blockKeywords(listView, keywords);
        navigationPane.pop();
        
        if (keywordsList.length == 0) {
            toaster.init( qsTr("The keyword could not be blocked: %1").arg(value), "images/ic_block.png" );
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
            toaster.init( qsTr("Could not find any suspicious keywords in the message..."), "images/ic_steps.png" );
        }
    }
    
    attachedObjects: [
        ComponentDefinition {
            id: definition
            source: "ElementPickerPage.qml"
        }
    ]
    
    onCreationCompleted: {
        deviceUtils.attachTopBottomKeys(conversationsPage, listView);
    }
}