import bb.cascades 1.0

Page
{
    id: root
    property variant elements
    property string titleText: qsTr("Keywords") + Retranslate.onLanguageChanged
    property string instructionText: qsTr("Do you want to automatically filter future messages that contain the following elements?") + Retranslate.onLanguageChanged
    signal elementsSelected(variant elements)
    
    function cleanUp() {}
    
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    
    onCreationCompleted: {
        deviceUtils.attachTopBottomKeys(root, listView);
    }
    
    onElementsChanged: {
        adm.clear();
        adm.insertList(elements);
    }
    
    titleBar: TitleBar {
        title: titleText
    }
    
    Container
    {
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill
        
        Container
        {
            topPadding: 10; rightPadding: 10; leftPadding: 10
            horizontalAlignment: HorizontalAlignment.Fill
            
            Label
            {
                id: instructions
                text: instructionText
                multiline: true
            }
        }
        
        Divider {
            topMargin: 0; bottomMargin: 0
        }
        
        ListView
        {
            id: listView
            scrollRole: ScrollRole.Main
            
            multiSelectHandler
            {
                onActiveChanged: {
                    if (active) {
                        tutorial.execActionBar( "tapAddReportedEntries", qsTr("Tap on the '%1' action to add the selected entries to your database.").arg(saveAction.title) );
                    }
                }
                
                actions: [
                    ActionItem
                    {
                        id: saveAction
                        enabled: false
                        imageSource: "images/menu/ic_accept_entries.png"
                        title: qsTr("Save") + Retranslate.onLanguageChanged
                        
                        onTriggered: {
                            console.log("UserEvent: SaveTriggered");
                            var selected = listView.selectionList();
                            var toBlock = [];
                            
                            for (var i = selected.length-1; i >= 0; i--) {
                                toBlock.push( adm.data(selected[i]) );
                            }
                            
                            elementsSelected(toBlock);
                        }
                    }
                ]
                
                status: qsTr("None selected") + Retranslate.onLanguageChanged
            }
            
            dataModel: GroupDataModel
            {
                id: adm
                grouping: ItemGrouping.ByFullValue
                sortingKeys: ["type", "value"]
            }
            
            onTriggered: {
                console.log("UserEvent: ElementTriggered", indexPath);
                
                if (indexPath.length > 1)
                {
                    multiSelectHandler.active = true;
                    toggleSelection(indexPath);
                } else {
                    reporter.record("HeaderTapped");
                }
            }
            
            onSelectionChanged: {
                var n = selectionList().length;
                saveAction.enabled = n > 0;
                multiSelectHandler.status = qsTr("%n entries selected", "", n);
            }
            
            listItemComponents: [
                ListItemComponent
                {
                    type: "header"
                    
                    Header {
                        title: ListItemData == "address" ? qsTr("Addresses") + Retranslate.onLanguageChanged : qsTr("Keywords") + Retranslate.onLanguageChanged
                        subtitle: ListItem.view.dataModel.childCount(ListItem.indexPath)
                    }
                },
                
                ListItemComponent
                {
                    type: "item"
                    
                    StandardListItem
                    {
                        id: sli
                        description: ListItemData.value
                        imageSource: ListItemData.type == "address" ? "images/list/list_address.png" : "images/list/list_keyword.png"
                        opacity: 0
                        
                        animations: [
                            FadeTransition
                            {
                                id: slider
                                fromOpacity: 0
                                toOpacity: 1
                                easingCurve: StockCurve.SineOut
                                duration: 750
                                delay: Math.min(sli.ListItem.indexInSection*100, 750)
                            }
                        ]
                        
                        onCreationCompleted: {
                            slider.play()
                        }
                    }
                }
            ]
        }
    }
}