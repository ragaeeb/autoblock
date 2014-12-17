import bb.cascades 1.0

Page
{
    id: root
    property variant elements
    property string titleText: qsTr("Keywords") + Retranslate.onLanguageChanged
    property string instructionText: qsTr("Do you want to automatically filter future messages that contain the following elements?") + Retranslate.onLanguageChanged
    property variant listImage: "images/menu/ic_keyword.png"
    property bool showSelectAll: reporter.isAdmin
    signal elementsSelected(variant elements)
    
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    
    onShowSelectAllChanged: {
        if (showSelectAll) {
            root.addAction(selectAllAction);
        } else {
            root.removeAction(selectAllAction);
        }
    }
    
    onCreationCompleted: {
        showSelectAllChanged();
    }
    
    onElementsChanged: {
        adm.clear();
        adm.insertList(elements);
    }
    
    titleBar: TitleBar
    {
        title: titleText
        
        acceptAction: ActionItem
        {
            id: saveAction
            enabled: false
            title: qsTr("Save") + Retranslate.onLanguageChanged
            
            onTriggered: {
                console.log("UserEvent: SaveTriggered");
                var selected = listView.selectionList();
                var toBlock = [];
                
                for (var i = selected.length-1; i >= 0; i--) {
                    toBlock.push( adm.data(selected[i]).value );
                }
                
                elementsSelected(toBlock);
            }
        }
    }
    
    actions: [
        ActionItem {
            id: clearAction
            title: qsTr("Clear All") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_clear.png"
            ActionBar.placement: ActionBarPlacement.OnBar
            
            onTriggered: {
                console.log("UserEvent: ClearAllSelection");
                listView.clearSelection();
            }
        },
        
        ActionItem {
            id: selectAllAction
            title: qsTr("Select All") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_select_all.png"
            ActionBar.placement: ActionBarPlacement.OnBar
            
            onTriggered: {
                console.log("UserEvent: SelectAllElements");
                
                var confirmed = persist.showBlockingDialog( qsTr("Confirmation"), qsTr("You should review the elements in this list. You may be selecting false positives! Are you sure you want to select all?") );
                console.log("UserEvent: SelectAllConfirmed", confirmed);
                
                if (confirmed) {
                    listView.selectAll();
                }
            }
        }
    ]
    
    Container
    {
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill
        
        Container
        {
            topPadding: 10; rightPadding: 10; leftPadding: 10
            horizontalAlignment: HorizontalAlignment.Fill
            
            Label {
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
            property variant imageSource: listImage
            
            dataModel: GroupDataModel {
                id: adm
                grouping: ItemGrouping.ByFirstChar
                sortingKeys: ["value"]
            }
            
            onTriggered: {
                console.log("UserEvent: ElementTriggered", indexPath);
                
                if (indexPath.length > 1) {
                    toggleSelection(indexPath);
                }
            }
            
            onSelectionChanged: {
                saveAction.enabled = selectionList().length > 0;
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
                    
                    StandardListItem
                    {
                        id: sli
                        description: ListItemData.value
                        imageSource: ListItem.view.imageSource
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
                        
                        onCreationCompleted: {
                            slider.play()
                        }
                    }
                }
            ]
        }
    }
}