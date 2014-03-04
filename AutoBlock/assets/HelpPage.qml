import bb.cascades 1.0
import bb 1.0

Page
{
    attachedObjects: [
        ApplicationInfo {
            id: appInfo
        },

        PackageInfo {
            id: packageInfo
        }
    ]
    
    actions: [
        InvokeActionItem
        {
            title: qsTr("Our BBM Channel") + Retranslate.onLanguageChanged
            ActionBar.placement: ActionBarPlacement.OnBar
            
            query {
                invokeTargetId: "sys.bbm.channels.card.previewer"
                uri: "bbmc:C0034D28B"
            }
        },
        
        InvokeActionItem {
            query {
                mimeType: "text/html"
                uri: "http://www.youtube.com/watch?v=rFoFPHxUF34"
                invokeActionId: "bb.action.OPEN"
            }
            
            imageSource: "images/ic_steps.png"
            title: qsTr("Video Tutorial") + Retranslate.onLanguageChanged
            ActionBar.placement: ActionBarPlacement.OnBar
        }
    ]
    
    titleBar: TitleBar {
        title: qsTr("Help") + Retranslate.onLanguageChanged
    }

    Container
    {
        rightPadding: 20; leftPadding: 20;

        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill

        ScrollView {
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Fill

            Label {
                multiline: true
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                textStyle.textAlign: TextAlign.Center
                textStyle.fontSize: FontSize.Small
                content.flags: TextContentFlag.ActiveText | TextContentFlag.EmoticonsOff
                text: qsTr("\n\n(c) 2013-2014 %1. All Rights Reserved.\n%2 %3\n\nPlease report all bugs to:\nsupport@canadainc.org\n\nTired of spammers irritating you with their advertisements and scams via SMS and email? Is there some crazy ex-partner that is constantly bugging you and you want to completely cut out of your life? Wish there was a way to automatically filter them out of your inbox without it affecting the conversations that actually matter in your life?\n\nAuto Block is the answer! This app will let you select which messages you consider to be spam, and tag them as such. The app will then begin monitoring your SMS and email inbox for any of the senders you marked to be spam and automatically delete them! You will not hear any notifications or see a blinking LED to disrupt your attention. Anyone who is on your contact list will not be affected, and their messages are never going to be inspected.\n\nTo deal with spammers who constantly change their numbers and email addresses, Auto Block has the new \"keyword filter\" feature. This allows you to pick, or manually add common keywords that the spammers use in their subject lines or message bodies and if future messages contain one of these words up to a specific threshold, then the message will automatically be marked as spam.\n\nAnd to make it even easier for our users to discover more and more spammers, Auto Block now has the built-in sharing functionality that allows you to sync with our servers to download the latest list of reported spammers. So you no longer have to do the heavy work yourself, but everyone can help each other as a team overcome the spammers from our inboxes.\n\n").arg(packageInfo.author).arg(appInfo.title).arg(appInfo.version)
            }
        }
    }
}
