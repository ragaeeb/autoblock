import bb.cascades 1.2

Delegate
{
    property variant data: []
    property bool suppress: persist.getValueFor("suppressTutorials") == 1
    
    function onSettingChanged(key) {
        if (key == "suppressTutorials") {
            suppress = persist.getValueFor("suppressTutorials");
        }
    }
    
    onCreationCompleted: {
        persist.settingChanged.connect(onSettingChanged);
    }
    
    function showNext()
    {
        if (data.length > 0)
        {
            var allData = data;
            var current = allData[allData.length-1];
            object.body = current.body;
            object.icon = current.icon;
            object.title = current.title;
        }
    }
    
    onObjectChanged: {
        if (object) {
            showNext();
            object.open();
        }
    }
    
    function init(text, iconUri) {
        initInternal(text, iconUri, "", qsTr("Alert!"));
    }
    
    function initInternal(text, iconUri, key, title)
    {
        if (text.length > 0)
        {
            var allData = data;
            
            for (var i = allData.length-1; i >= 0; i--)
            {
                if ( allData[i].key == key ) {
                    return;
                }
            }
            
            allData.push( {'key': key, 'body': text, 'icon': iconUri, 'title': title} );
            data = allData;

            if (!active) {
                active = true;
            } else {
                showNext();
            }
        }
    }
    
    function tutorial(key, text, imageUri)
    {
        if ( !persist.contains(key) && !suppress )
        {
            initInternal(text, imageUri, key, qsTr("Tip!"));
            return true;
        }
        
        return false;
    }
    
    sourceComponent: ComponentDefinition
    {
        Dialog
        {
            id: root
            property alias body: bodyLabel.text
            property alias icon: toastIcon.imageSource
            property alias title: tipLabel.text
            
            onOpened: {
                mainAnim.play();
            }
            
            function dismiss()
            {
                if (data.length > 0)
                {
                    var allData = data;
                    var key = allData.pop().key;
                    data = allData;
                    
                    if (key.length > 0) {
                        persist.saveValueFor(key, 1, false);
                    }
                }
                
                if (data.length > 0) {
                    showNext();
                    iconRotate.play();
                } else if ( !fadeOut.isPlaying() ) {
                    fadeOut.play();
                }
            }
            
            Container
            {
                id: dialogContainer
                preferredWidth: Infinity
                preferredHeight: Infinity
                background: Color.create(0,0,0,0.5)
                layout: DockLayout {}
                opacity: 0
                
                Container
                {
                    id: toastBg
                    topPadding: 10; leftPadding: 10; rightPadding: 10; bottomPadding: 30
                    horizontalAlignment: HorizontalAlignment.Center
                    verticalAlignment: VerticalAlignment.Center
                    background: bg.imagePaint
                    minHeight: 100
                    minWidth: 300
                    maxWidth: 550
                    maxHeight: 550
                    
                    Container
                    {
                        horizontalAlignment: HorizontalAlignment.Fill
                        
                        layout: StackLayout {
                            orientation: LayoutOrientation.LeftToRight
                        }
                        
                        ImageView {
                            id: infoImage
                            imageSource: "images/toast/tutorial_info.png"
                            verticalAlignment: VerticalAlignment.Center
                            loadEffect: ImageViewLoadEffect.FadeZoom
                            translationX: -500
                        }
                        
                        Label {
                            id: tipLabel
                            textStyle.fontSize: FontSize.XXSmall
                            textStyle.fontWeight: FontWeight.Bold
                            verticalAlignment: VerticalAlignment.Top
                            horizontalAlignment: HorizontalAlignment.Fill
                            translationX: 500
                            
                            layoutProperties: StackLayoutProperties {
                                spaceQuota: 1
                            }
                        }
                        
                        ImageButton
                        {
                            id: closeButton
                            defaultImageSource: "images/toast/toast_close.png"
                            pressedImageSource: defaultImageSource
                            horizontalAlignment: HorizontalAlignment.Right
                            verticalAlignment: VerticalAlignment.Center
                            rotationZ: 360
                            translationX: 1000
                            
                            onClicked: {
                                if ( !mainAnim.isPlaying() ) {
                                    console.log("UserEvent: NotificationCloseButton");
                                    root.dismiss();
                                }
                            }
                            
                            onCreationCompleted: {
                                persist.attachBackKeyToClickedSignal(closeButton, dialogContainer);
                            }
                        }
                    }
                    
                    ImageView
                    {
                        id: toastIcon
                        horizontalAlignment: HorizontalAlignment.Center
                        verticalAlignment: VerticalAlignment.Center
                        loadEffect: ImageViewLoadEffect.FadeZoom
                        opacity: 0
                        
                        animations: [
                            RotateTransition
                            {
                                id: iconRotate
                                fromAngleZ: 0
                                toAngleZ: 360
                                duration: 750
                                easingCurve: StockCurve.QuarticIn
                            }
                        ]
                    }
                    
                    Container
                    {
                        leftPadding: 20; topPadding: 10
                        verticalAlignment: VerticalAlignment.Fill
                        horizontalAlignment: HorizontalAlignment.Fill
                        
                        Label {
                            id: bodyLabel
                            multiline: true
                            textStyle.fontSize: FontSize.XSmall
                            textStyle.fontStyle: FontStyle.Italic
                            scaleX: 1.25
                            scaleY: 1.25
                            opacity: 0
                        }
                    }
                    
                    attachedObjects: [
                        ImagePaintDefinition {
                            id: bg
                            imageSource: "images/toast/toast_bg.amd"
                        }
                    ]
                }
                
                gestureHandlers: [
                    TapHandler {
                        onTapped: {
                            console.log("UserEvent: NotificationToastTapped");
                            
                            if (event.propagationPhase == PropagationPhase.AtTarget)
                            {
                                console.log("UserEvent: NotificationOutsideBounds");
                                
                                if ( mainAnim.isPlaying() )
                                {
                                    mainAnim.stop();
                                    dialogContainer.opacity = dialogFt.toOpacity;
                                    closeButton.translationX = closeTt.toX;
                                    toastIcon.opacity = toastIconFt.toOpacity;
                                    toastIcon.rotationZ = toastIconRt.toAngleZ;
                                    infoImage.translationX = infoImageTt.toX;
                                    tipLabel.translationX = tipLabelTt.toX;
                                    infoImage.rotationZ = infoImageRt.toAngleZ;
                                    closeButton.rotationZ = closeButtonRt.toAngleZ;
                                    bodyLabel.opacity = bodyLabelFt.toOpacity;
                                    bodyLabel.scaleX = bodyLabelSt.toX;
                                    bodyLabel.scaleY = bodyLabelSt.toY;
                                } else {
                                    root.dismiss();
                                }
                            }
                        }
                    }
                ]
            }
            
            onClosed: {
                active = false;
            }
            
            attachedObjects: [
                SequentialAnimation
                {
                    id: mainAnim
                    
                    FadeTransition {
                        id: dialogFt
                        target: dialogContainer
                        fromOpacity: 0
                        toOpacity: 1
                        duration: 250
                        easingCurve: StockCurve.SineOut
                    }
                    
                    ParallelAnimation
                    {
                        TranslateTransition
                        {
                            id: closeTt
                            target: closeButton
                            duration: 250
                            fromX: -500
                            toX: 0
                            easingCurve: StockCurve.QuinticOut
                        }
                        
                        FadeTransition
                        {
                            id: toastIconFt
                            fromOpacity: 0
                            toOpacity: 1
                            target: toastIcon
                            duration: 400
                            easingCurve: StockCurve.ExponentialInOut
                        }
                        
                        RotateTransition
                        {
                            id: toastIconRt
                            fromAngleZ: 0
                            toAngleZ: 360
                            target: toastIcon
                            duration: 500
                            delay: 250
                            easingCurve: StockCurve.CubicInOut
                        }
                        
                        TranslateTransition
                        {
                            id: infoImageTt
                            target: infoImage
                            duration: 250
                            fromX: 1000
                            toX: 0
                            easingCurve: StockCurve.CubicOut
                        }
                        
                        TranslateTransition
                        {
                            id: tipLabelTt
                            target: tipLabel
                            delay: 250
                            duration: 400
                            fromX: 500
                            toX: 0
                            easingCurve: StockCurve.ExponentialOut
                        }
                    }
                    
                    ParallelAnimation
                    {
                        RotateTransition
                        {
                            id: infoImageRt
                            target: infoImage
                            fromAngleZ: 0
                            toAngleZ: 360
                            duration: 400
                            easingCurve: StockCurve.ExponentialIn
                        }

                        RotateTransition
                        {
                            id: closeButtonRt
                            target: closeButton
                            delay: 150
                            fromAngleZ: 360
                            toAngleZ: 0
                            duration: 350
                            easingCurve: StockCurve.CircularOut
                        }
                    }
                    
                    ParallelAnimation
                    {
                        target: bodyLabel

                        FadeTransition
                        {
                            id: bodyLabelFt
                            fromOpacity: 0
                            toOpacity: 1
                            duration: 250
                            easingCurve: StockCurve.QuadraticOut
                        }
                        
                        ScaleTransition
                        {
                            id: bodyLabelSt
                            fromX: 1.5
                            fromY: 1.5
                            toX: 1
                            toY: 1
                            duration: 500
                            easingCurve: StockCurve.DoubleBounceIn
                        }
                    }
                },
                
                ParallelAnimation
                {
                    id: fadeOut
                    
                    FadeTransition {
                        fromOpacity: 1
                        toOpacity: 0
                        duration: 500
                        easingCurve: StockCurve.QuinticIn
                        target: dialogContainer
                    }
                    
                    TranslateTransition
                    {
                        target: toastBg
                        fromY: 0
                        toY: 1000
                        duration: 500
                        easingCurve: StockCurve.BackIn
                    }
                    
                    onEnded: {
                        root.close();
                    }
                }
            ]
        }
    }    
}