import bb.cascades 1.0

TitleBar
{
    kind: TitleBarKind.FreeForm
    kindProperties: FreeFormTitleBarKindProperties
    {
        Container
        {
            background: back.imagePaint
            
            attachedObjects: [
                ImagePaintDefinition {
                    id: back
                    imageSource: "images/background.png"
                }
            ]
            
            Container {
                layout: DockLayout {}
                
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Top
                
                ImageView {
                    imageSource: "images/titlebar/title_bg.png"
                    topMargin: 0
                    leftMargin: 0
                    rightMargin: 0
                    bottomMargin: 0
                    
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Fill
                }
                
                Container
                {
                    id: arrows1
                    opacity: 0
                    leftPadding: 120; topPadding: 93
                    
                    ImageView {
                        imageSource: "images/titlebar/arrows1.png"
                        horizontalAlignment: HorizontalAlignment.Left
                    }
                    
                    onCreationCompleted: {
                        arrow1Fade.play();
                    }
                    
                    animations: [
                        FadeTransition {
                            id: arrow1Fade
                            fromOpacity: 0
                            toOpacity: 1
                            duration: 1000
                            
                            onEnded: {
                                arrow2Fade.play();
                            }
                        }
                    ]
                }
                
                Container
                {
                    opacity: 0
                    id: arrows2
                    topPadding: 102
                    
                    ImageView {
                        imageSource: "images/titlebar/arrows2.png"
                        horizontalAlignment: HorizontalAlignment.Left
                    }
                    
                    animations: [
                        FadeTransition {
                            id: arrow2Fade
                            fromOpacity: 0
                            toOpacity: 1
                            duration: 1000
                            
                            onEnded: {
                                if (arrows2.opacity == 1) {
                                    arrow1Fade.fromOpacity = fromOpacity = 1;
                                    arrow2Fade.toOpacity = toOpacity = 0;
                                } else {
                                    arrow1Fade.fromOpacity = fromOpacity = 0;
                                    arrow2Fade.toOpacity = toOpacity = 1;
                                }
                            }
                        }
                    ]
                }
                
                Container
                {
                    horizontalAlignment: HorizontalAlignment.Right
                    verticalAlignment: VerticalAlignment.Center
                    
                    rightPadding: 20
                    
                    layout: StackLayout {
                        orientation: LayoutOrientation.LeftToRight
                    }
                    
                    animations: [
                        ParallelAnimation {
                            id: fadeTranslate
                            
                            FadeTransition {
                                duration: 1000
                                easingCurve: StockCurve.CubicIn
                                fromOpacity: 0
                                toOpacity: 1
                            }
                            
                            TranslateTransition {
                                toY: 0
                                fromY: -100
                                duration: 1000
                            }
                        }
                    ]
                    
                    onCreationCompleted: {
                        fadeTranslate.play();
                    }
                    
                    ImageView {
                        imageSource: "images/logo.png"
                        verticalAlignment: VerticalAlignment.Fill
                        
                        animations: [
                            RotateTransition {
                                id: rotator
                                fromAngleZ: 360
                                toAngleZ: 0
                                duration: 1000
                            }
                        ]
                        
                        onCreationCompleted: {
                            rotator.play();
                        }
                    }
                    
                    ImageView {
                        imageSource: "images/titlebar/title_text.png"
                        topMargin: 0
                        leftMargin: 10
                        rightMargin: 0
                        bottomMargin: 0
                        verticalAlignment: VerticalAlignment.Center
                    }
                }
            }
        }
    }
}