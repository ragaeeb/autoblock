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
            imageSource: "images/progress/setup.png"
            
            animations: [
                SequentialAnimation
                {
                    id: breatheAnimation
                    repeatCount: AnimationRepeatCount.Forever
                    
                    ScaleTransition {
                        fromX: 1
                        fromY: 1
                        toX: 1.2
                        toY: 1.2
                        duration: 900
                        easingCurve: StockCurve.CubicInOut
                    }

                    ScaleTransition {
                        fromX: 1.2
                        fromY: 1.2
                        toX: 1
                        toY: 1
                        duration: 900
                        easingCurve: StockCurve.CubicOut
                    }
                },
                
                ScaleTransition
                {
                    id: exitAnim
                    fromX: 1
                    toX: 0
                    fromY: 1
                    toY: 0
                    
                    onEnded: {
                        close();
                    }
                }
            ]
        }
        
        Label
        {
            textStyle.textAlign: TextAlign.Center
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Center
            textStyle.base: SystemDefaults.TextStyles.BigText
            textStyle.fontWeight: FontWeight.Bold
            textStyle.color: Color.White
            opacity: 0.8
            text: qsTr("Setup in progress...") + Retranslate.onLanguageChanged
        }
        
        Label
        {
            textStyle.textAlign: TextAlign.Center
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Top
            textStyle.base: SystemDefaults.TextStyles.BodyText
            textStyle.color: Color.create("#F0F8FF")
            multiline: true
            opacity: 0.9
            text: qsTr("If this screen remains indefinitely it means that you may have accidentally disabled the background service from running.\nClick here to fix it.") + Retranslate.onLanguageChanged
            
            gestureHandlers: [
                TapHandler {
                    onTapped: {
                        console.log("UserEvent: LaunchPermissions");
                        persist.launchAppPermissionSettings();
                    }
                }
            ]
        }
    }
    
    onOpened: {
        breatheAnimation.play();
    }
    
    function onReady() {
        exitAnim.play();
    }
    
    onCreationCompleted: {
        helper.readyChanged.connect(onReady);
    }
}