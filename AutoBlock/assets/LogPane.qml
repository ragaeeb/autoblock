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
        actions: [
            SearchActionItem
            {
                imageSource: "images/menu/ic_search_logs.png"
                
                onQueryChanged: {
                    helper.fetchAllLogs(query);
                }
            },
            
            DeleteActionItem
            {
                title: qsTr("Clear Logs") + Retranslate.onLanguageChanged
                imageSource: "images/menu/ic_clear_logs.png"
                
                onTriggered: {
                    console.log("UserEvent: ClearLogs");
                    prompt.show();
                }
                
                attachedObjects: [
                    SystemDialog {
                        id: prompt
                        title: qsTr("Confirmation") + Retranslate.onLanguageChanged
                        body: qsTr("Are you sure you want to clear all the logs?") + Retranslate.onLanguageChanged
                        confirmButton.label: qsTr("Yes") + Retranslate.onLanguageChanged
                        cancelButton.label: qsTr("No") + Retranslate.onLanguageChanged
                        
                        onFinished: {
                            console.log("UserEvent: ClearLogsPrompt", result);
                            
                            if (value == SystemUiResult.ConfirmButtonSelection)
                            {
                                helper.clearLogs();
                                persist.showToast( qsTr("Cleared all blocked senders!"), "", "asset:///images/menu/ic_clear_logs.png" );
                            }
                        }
                    }
                ]
            }
        ]
        
        titleBar: AutoBlockTitleBar {}
        
        Container
        {
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            background: ipd.imagePaint
            layout: DockLayout {}
            
            EmptyDelegate
            {
                id: emptyDelegate
                graphic: "images/empty/ic_empty_logs.png"
                labelText: qsTr("No spam messages detected yet.") + Retranslate.onLanguageChanged
            }
            
            ListView
            {
                id: listView
                property variant localizer: app
                
                listItemComponents: [
                    ListItemComponent
                    {
                        StandardListItem
                        {
                            id: sli
                            title: ListItemData.address
                            imageSource: "images/menu/ic_log.png"
                            description: ListItemData.message.replace(/\n/g, " ").substr(0, 120) + "..."
                            status: ListItem.view.localizer.renderStandardTime( new Date(ListItemData.timestamp) )
                            opacity: 0
                            
                            animations: [
                                FadeTransition {
                                    id: slider
                                    fromOpacity: 0
                                    toOpacity: 1
                                    easingCurve: StockCurve.SineOut
                                    duration: 800
                                    delay: sli.ListItem.indexInSection * 100
                                }
                            ]
                            
                            onCreationCompleted: {
                                slider.play();
                            }
                        }
                    }
                ]
                
                onTriggered: {
                    console.log("UserEvent: LogTapped", indexPath);
                    var data = dataModel.data(indexPath);
                    persist.showToast( data.message.trim(), qsTr("OK"), "asset:///images/tabs/ic_blocked.png" );
                }
                
                dataModel: ArrayDataModel {
                    id: adm
                }
                
                function onDataLoaded(id, data)
                {
                    if (id == QueryId.FetchAllLogs || id == QueryId.ClearLogs)
                    {
                        adm.clear();
                        adm.append(data);
                        
                        if ( adm.size() > 10 ) {
                            if ( persist.tutorial("tutorialSearchLogs", qsTr("You can use the 'Search' action from the menu to search the logs if a specific message that was blocked."), "asset:///images/menu/ic_search_logs.png" ) ) {}
                            else if ( persist.tutorial("tutorialClearLogs", qsTr("If this list is getting too cluttered, you can always clear the logs by using the 'Clear Logs' action from the menu."), "asset:///images/menu/ic_clear_logs.png" ) ) {}
                        }
                    } else if (id == QueryId.FetchLatestLogs) {
                        adm.insert(0, data);
                        listView.scrollToPosition(ScrollPosition.Beginning, ScrollAnimation.Smooth);
                    }
                    
                    listView.visible = !adm.isEmpty();
                    emptyDelegate.delegateActive = adm.isEmpty();
                    
                    var tutorialText = "";
                    var icon = ""
                    
                    if ( !persist.contains("tutorialLogPane") ) {
                        tutorialText = qsTr("In this tab you will be able to modify the reply text that you wish to send out when your contacts message you.");
                        persist.saveValueFor("tutorialLogPane", 1, false);
                    } else if ( !persist.contains("tutorialHelp") ) {
                        tutorialText = qsTr("To get more help, swipe-down from the top-bezel and choose the 'Help' action.");
                        icon = "images/menu/ic_help.png";
                        persist.saveValueFor("tutorialHelp", 1, false);
                    } else if ( !persist.contains("tutorialSettings") ) {
                        tutorialText = qsTr("To change the blue LED blinking, swipe-down from the top-bezel and choose the 'Settings' action.");
                        icon = "images/menu/ic_settings.png";
                        persist.saveValueFor("tutorialSettings", 1, false);
                    } else if ( !persist.contains("tutorialBugReports") ) {
                        tutorialText = qsTr("If you notice any bugs in the app that you want to report or you want to file a feature request, swipe-down from the top-bezel and choose the 'Bug Reports' action.");
                        icon = "images/ic_bugs.png";
                        persist.saveValueFor("tutorialBugReports", 1, false);
                    }
                    
                    tutorialToast.init(tutorialText, icon);
                }
                
                function setupComplete()
                {
                    helper.dataReady.connect(onDataLoaded);
                    helper.fetchAllLogs();
                }
                
                function onReady()
                {
                    helper.checkDatabase();
                    
                    if (helper.ready) {
                        setupComplete();
                    } else {
                        helper.readyChanged.connect(setupComplete);

                        definition.source = "SetupDialog.qml";
                        var setup = definition.createObject();
                        
                        setup.open();
                    }
                }
                
                onCreationCompleted: {
                    app.lazyInitComplete.connect(onReady);
                }
            }
            
            PermissionToast
            {
                id: tm
                horizontalAlignment: HorizontalAlignment.Right
                verticalAlignment: VerticalAlignment.Center
            }
            
            attachedObjects: [
                ImagePaintDefinition {
                    id: ipd
                    imageSource: "images/background.png"
                },
                
                ComponentDefinition {
                    id: definition
                }
            ]
        }
    }
}