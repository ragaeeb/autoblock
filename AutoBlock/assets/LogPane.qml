import bb.cascades 1.2
import bb.system 1.0
import com.canadainc.data 1.0

NavigationPane
{
    id: navigationPane
    property alias permissionToast: tm

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
            
            ActionItem {
                imageSource: "images/menu/ic_test.png"
                title: qsTr("Test") + Retranslate.onLanguageChanged
                
                onTriggered: {
                    shortcut.active = true;
                    shortcut.object.testPrompt.reset();
                    shortcut.object.testPrompt.show();
                }
                
                attachedObjects: [
                    Delegate {
                        id: shortcut
                        active: false
                        source: "TestHelper.qml"
                    }
                ]
                
                shortcuts: [
                    SystemShortcut {
                        type: SystemShortcuts.CreateNew
                    }
                ]
            },
            
            DeleteActionItem
            {
                id: clearLogsAction
                enabled: listView.visible
                title: qsTr("Clear Logs") + Retranslate.onLanguageChanged
                imageSource: "images/menu/ic_clear_logs.png"
                
                onTriggered: {
                    console.log("UserEvent: ClearLogs");
                    
                    var ok = persist.showBlockingDialog( qsTr("Confirmation"), qsTr("Are you sure you want to clear all the logs?") );
                    console.log("UserEvent: ClearLogsConfirm", ok);
                    
                    if (ok) {
                        helper.clearLogs();
                        tutorialToast.init( qsTr("Cleared all blocked senders!"), "images/menu/ic_clear_logs.png" );
                    }
                }
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
                property variant localizer: offloader
                
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
                    tutorialToast.init( data.message.trim(), "asset:///images/tabs/ic_blocked.png" );
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
                        
                        if ( id == QueryId.FetchAllLogs && adm.size() > 300 && !persist.contains("dontAskToClear") ) {
                            clearDialog.showing = true;
                        }
                    } else if (id == QueryId.FetchLatestLogs) {
                        adm.insert(0, data);
                        listView.scrollToPosition(ScrollPosition.Beginning, ScrollAnimation.Smooth);
                    }

                    listView.visible = !adm.isEmpty();
                    emptyDelegate.delegateActive = adm.isEmpty();
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
                        
                        if ( tutorialToast.tutorial("tutorialLogPane", qsTr("In this tab you will be able to view all the messages that were blocked."), "images/tabs/ic_logs.png") ) {}
                        else if ( tutorialToast.tutorial("tutorialHelp", qsTr("To get more help, swipe-down from the top-bezel and choose the 'Help' action."), "images/menu/ic_help.png") ) {}
                        else if ( tutorialToast.tutorial("tutorialSettings", qsTr("To move the junk mail to the Trash folder instead of permanently deleting them, swipe-down from the top-bezel and go to Settings."), "images/menu/ic_settings.png") ) {}
                        else if ( tutorialToast.tutorial("tutorialBugReports", qsTr("If you notice any bugs in the app that you want to report or you want to file a feature request, swipe-down from the top-bezel and choose the 'Bug Reports' action."), "images/ic_bugs.png") ) {}
                        else if ( tutorialToast.tutorial("tutorialSearchLogs", qsTr("You can use the 'Search' action from the menu to search the logs if a specific message that was blocked."), "images/menu/ic_search_logs.png") ) {}
                        else if ( tutorialToast.tutorial("tutorialClearLogs", qsTr("If this list is getting too cluttered, you can always clear the logs by using the 'Clear Logs' action from the menu."), "images/menu/ic_clear_logs.png") ) {}
                        else if ( persist.reviewed() ) {}
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
                
                SystemDialog {
                    id: clearDialog
                    property bool showing: false
                    body: qsTr("You seem to have a lot of entries here, would you like to clear this list to improve app startup time?") + Retranslate.onLanguageChanged
                    title: qsTr("Clear Logs") + Retranslate.onLanguageChanged
                    cancelButton.label: qsTr("No") + Retranslate.onLanguageChanged
                    confirmButton.label: qsTr("Yes") + Retranslate.onLanguageChanged
                    rememberMeChecked: false
                    includeRememberMe: true
                    rememberMeText: qsTr("Don't Ask Again") + Retranslate.onLanguageChanged
                    
                    onShowingChanged: {
                        if (showing) {
                            show();
                        }
                    }
                    
                    onFinished: {
                        showing = false;
                        console.log("UserEvent: ClearNoticePrompt", value);
                        
                        if (value == SystemUiResult.ConfirmButtonSelection) {
                            helper.clearLogs();
                            tutorialToast.init( qsTr("Cleared all blocked senders!"), "images/menu/ic_clear_logs.png" );
                        } else if ( rememberMeSelection() ) {
                            persist.saveValueFor("dontAskToClear", 1, false);
                        }
                    }
                },
                
                ComponentDefinition {
                    id: definition
                }
            ]
        }
    }
}