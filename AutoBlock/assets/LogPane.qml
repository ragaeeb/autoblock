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
            SearchActionItem {
                imageSource: "images/menu/ic_search_logs.png"
                
                onQueryChanged: {
                    helper.fetchAllLogs(query);
                }
            },
            
            DeleteActionItem {
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
                            
                            if (result == SystemUiResult.ConfirmButtonSelection)
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
                property LocaleUtil localizer: LocaleUtil {}
                
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
                                slider.play()
                            }
                        }
                    }
                ]
                
                onTriggered: {
                    console.log("UserEvent: Log Tapped", indexPath);
                    var data = dataModel.data(indexPath);
                    persist.showToast( data.message.trim(), qsTr("OK"), "asset:///images/tabs/ic_blocked.png" );
                }
                
                dataModel: ArrayDataModel {
                    id: adm
                }
                
                function onDataLoaded(id, data)
                {
                    if (id == QueryId.FetchAllLogs || id == QueryId.ClearLogs) {
                        adm.clear();
                        adm.append(data);
                    } else if (id == QueryId.FetchLatestLogs) {
                        adm.insert(0, data);
                    }
                    
                    listView.visible = !adm.isEmpty();
                    emptyDelegate.delegateActive = adm.isEmpty();
                }
                
                onCreationCompleted: {
                    helper.dataReady.connect(onDataLoaded);
                    helper.fetchAllLogs();
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