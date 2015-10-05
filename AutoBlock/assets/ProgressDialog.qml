import bb.cascades 1.0

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
            imageSource: "images/progress/spinner.png"
            
            onCreationCompleted: {
                rt.play();
            }
            
            animations: [
                SequentialAnimation {
                    id: rt
                    
                    ScaleTransition {
                        fromY: 0
                        toY: -1.5
                        duration: 1000
                        easingCurve: StockCurve.SineIn
                    }
                    
                    RotateTransition {
                        delay: 0
                        easingCurve: StockCurve.SineOut
                        fromAngleZ: 0
                        toAngleZ: 360
                        duration: 1000
                        repeatCount: AnimationRepeatCount.Forever
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
            multiline: true
            textStyle.fontWeight: FontWeight.Bold
            textStyle.color: Color.White
            opacity: 0.8
            text: qsTr("Downloading...") + Retranslate.onLanguageChanged
            
            function onDownloadProgress(cookie, received, total) {
                text = app.bytesToSize(received);
            }
            
            function onStatusUpdate(value) {
                text = value;
            }
            
            onCreationCompleted: {
                updater.downloadProgress.connect(onDownloadProgress);
                updater.statusUpdate.connect(onStatusUpdate);
            }
        }
    }
}