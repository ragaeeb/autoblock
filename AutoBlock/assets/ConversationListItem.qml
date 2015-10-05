import bb.cascades 1.0

StandardListItem
{
    enabled: ListItemData.senderAddress.length > 0
    status: offloader.renderStandardTime(ListItemData.time)
    title: ListItemData.sender
    
    animations: [
        FadeTransition
        {
            id: slider
            fromOpacity: 0
            toOpacity: 1
            easingCurve: StockCurve.SineInOut
            duration: 400
        }
    ]
    
    ListItem.onInitializedChanged: {
        if (initialized) {
            slider.play();
        }
    }
}