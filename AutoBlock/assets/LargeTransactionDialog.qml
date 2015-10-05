import bb.cascades 1.0
import com.canadainc.data 1.0

FullScreenDialog
{
    dialogContent: Container
    {
        bottomPadding: 30
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill
        
        layout: DockLayout {}
        
        ImageView
        {
            id: spinner
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Center
            imageSource: "images/progress/processing.png"
            translationX: -150
            
            animations: [
                SequentialAnimation
                {
                    id: writeAnimation
                    repeatCount: AnimationRepeatCount.Forever
                    
                    TranslateTransition {
                        fromX: -150
                        toX: 150
                        duration: 3000
                        easingCurve: StockCurve.CubicInOut
                    }

                    TranslateTransition {
                        fromX: 150
                        toX: -150
                        duration: 500
                        easingCurve: StockCurve.CubicOut
                    }
                }
            ]
        }
        
        Label {
            id: label
            textStyle.textAlign: TextAlign.Center
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Center
            textStyle.base: SystemDefaults.TextStyles.BigText
            textStyle.fontWeight: FontWeight.Bold
            textStyle.color: Color.White
            opacity: 0.8
            text: qsTr("Processing...") + Retranslate.onLanguageChanged
        }
    }
    
    onOpened: {
        writeAnimation.play();
    }
    
    function onDataLoaded(id, data)
    {
        if (id == QueryId.BlockSenders) {
            close();
        }
    }
    
    onCreationCompleted: {
        helper.dataReady.connect(onDataLoaded);
    }
}