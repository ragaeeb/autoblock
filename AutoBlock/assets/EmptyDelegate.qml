import bb.cascades 1.0

ControlDelegate
{
    property variant graphic
    property string labelText
    delegateActive: false
    signal imageTapped();
    
    horizontalAlignment: HorizontalAlignment.Fill
    verticalAlignment: VerticalAlignment.Center
    
    sourceComponent: ComponentDefinition
    {
        Container
        {
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            leftPadding: 80
            rightPadding: 80
            
            ImageView {
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                imageSource: graphic
                scalingMethod: ScalingMethod.AspectFit
                
                gestureHandlers: [
                    TapHandler {
                        onTapped: {
                            imageTapped();
                        }
                    }
                ]
            }
            
            Label {
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                multiline: true
                textStyle.fontSize: FontSize.Large
                textStyle.textAlign: TextAlign.Center
                text: labelText
            }
        }
    }
}