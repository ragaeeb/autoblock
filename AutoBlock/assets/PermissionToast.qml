import bb.cascades 1.0

ControlDelegate
{
    delegateActive: false
    property variant messages
    property variant icons
    
    sourceComponent: ComponentDefinition
    {
        Container
        {
            id: mainContainer
            horizontalAlignment: HorizontalAlignment.Fill
            translationX: 500
            maxWidth: 500
            maxHeight: 500
            layout: DockLayout {}
            
            function showNext()
            {
                var allMessages = messages;
                var allIcons = icons;
                
                warning.text = allMessages.pop();
                infoImage.imageSource = allIcons.pop();
                
                messages = allMessages;
                icons = allIcons;
                
                rotator.play();
            }
            
            ImageView {
                imageSource: "images/toast/permission_toast_bg.amd"
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Fill
            }
            
            ScrollView
            {
                Container
                {
                    horizontalAlignment: HorizontalAlignment.Fill
                    topPadding: 10; leftPadding: 15; rightPadding: 50; bottomPadding: 30
                    
                    ImageView
                    {
                        id: infoImage
                        horizontalAlignment: HorizontalAlignment.Center
                        verticalAlignment: VerticalAlignment.Center
                        
                        animations: [
                            RotateTransition {
                                id: rotator
                                fromAngleZ: 0
                                toAngleZ: 360
                                delay: 750
                                duration: 1000
                                easingCurve: StockCurve.QuarticOut
                            }
                        ]
                    }
                    
                    Label
                    {
                        id: warning
                        topMargin: 0
                        textStyle.color: Color.White
                        multiline: true
                        verticalAlignment: VerticalAlignment.Fill
                        textStyle.fontSize: FontSize.XXSmall
                    }
                }
            }
            
            animations: [
                TranslateTransition {
                    id: tt
                    fromX: 500
                    toX: 0
                    easingCurve: StockCurve.SineIn
                    duration: 1000
                }
            ]
            
            onCreationCompleted: {
                tt.play();
                showNext();
            }
            
            gestureHandlers: [
                TapHandler
                {
                    onTapped: {
                        console.log("UserEvent: WarningTapped");
                        var allMessages = messages;
                        
                        if (allMessages.length >= 1) {
                            mainContainer.showNext();
                        } else {
                            persist.launchAppPermissionSettings();
                            dth.doubleTapped(undefined);
                        }
                    }
                },
                
                DoubleTapHandler
                {
                    id: dth
                    
                    onDoubleTapped: {
                        console.log("UserEvent: WarningDoubleTapped")
                        tt.fromX = 0;
                        tt.toX = 500;
                        tt.duration = 500;
                        tt.play();
                    }
                }
            ]
        }
    }
    
    function onReady()
    {
        var allMessages = [];
        var allIcons = [];
        
        if ( !persist.hasEmailSmsAccess() ) {
            allMessages.push("Warning: It seems like the app does not have access to your Email/SMS messages Folder. This permission is needed for the app to access the SMS and email services it needs to do the filtering of the spam messages. If you leave this permission off, some features may not work properly. Select OK to launch the Application Permissions screen where you can turn these settings on.");
            allIcons.push("images/toast/no_email_access.png");
        }
        
        if ( !persist.hasSharedFolderAccess() ) {
            allMessages.push("Warning: It seems like the app does not have access to your Shared Folder. This permission is needed for the app to properly allow you to backup & restore the database. If you leave this permission off, some features may not work properly. Select OK to launch the Application Permissions screen where you can turn these settings on.");
            allIcons.push("images/toast/no_shared_folder.png");
        }
        
        if ( !persist.hasPhoneControlAccess() ) {
            allMessages.push("Warning: It seems like the app does not have access to control your phone. This permission is needed for the app to access the phone service required to be able to block calls based on the incoming number. Select OK to launch the Application Permissions screen where you can turn these settings on.");
            allIcons.push("images/toast/no_phone_control.png");
        }

        if (allMessages.length > 0)
        {
            messages = allMessages;
            icons = allIcons;
            delegateActive = true;
        }
    }
    
    onCreationCompleted: {
        app.lazyInitComplete.connect(onReady);
    }
}