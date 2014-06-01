import bb.cascades 1.0

Page
{
    id: root
    property variant elements
    property string titleText: qsTr("Keywords") + Retranslate.onLanguageChanged
    signal elementsSelected(variant elements)
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    property string instructionText: qsTr("Do you want to automatically filter future messages that contain the following elements?") + Retranslate.onLanguageChanged
    property variant listImage: "images/menu/ic_keyword.png"
    
    onElementsChanged: {
        adm.clear();
        adm.append(elements);
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
                    toBlock.push( adm.data(selected[i]) );
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
            
            dataModel: ArrayDataModel {
                id: adm
            }
            
            onTriggered: {
                console.log("UserEvent: Element Toggle", indexPath);
                toggleSelection(indexPath);
            }
            
            onSelectionChanged: {
                saveAction.enabled = selectionList().length > 0;
            }
            
            listItemComponents: [
                ListItemComponent
                {
                    StandardListItem
                    {
                        id: sli
                        title: ListItemData
                        imageSource: ListItem.view.imageSource
                        opacity: 0
                        
                        animations: [
                            FadeTransition {
                                id: slider
                                fromOpacity: 0
                                toOpacity: 1
                                easingCurve: StockCurve.SineOut
                                duration: 1000
                                delay: Math.min(sli.ListItem.indexInSection * 100, 1000)
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