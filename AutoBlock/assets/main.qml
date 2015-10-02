import bb.cascades 1.2
import com.canadainc.data 1.0

TabbedPane
{
    id: root
    activeTab: logTab
    showTabsOnActionBar: true
    
    Menu.definition: CanadaIncMenu
    {
        help.imageSource: "images/menu/ic_help.png"
        help.title: qsTr("Help") + Retranslate.onLanguageChanged
        settings.imageSource: "images/menu/ic_settings.png"
        settings.title: qsTr("Settings") + Retranslate.onLanguageChanged
        projectName: "autoblock"
        bbWorldID: "25793872"
        
        onFinished: {
            if ( persist.getValueFor("startAtConversations") == 1 ) {
                activeTab = conversationsTab;
            }
            
            var allMessages = [];
            var allIcons = [];
            
            if ( !persist.hasEmailSmsAccess() ) {
                allMessages.push("Warning: It seems like the app does not have access to your Email/SMS messages Folder. This permission is needed for the app to access the SMS and email services it needs to do the filtering of the spam messages. If you leave this permission off, some features may not work properly. Select the icon to launch the Application Permissions screen where you can turn these settings on.");
                allIcons.push("images/toast/no_email_access.png");
            }
            
            if ( !persist.hasSharedFolderAccess() ) {
                allMessages.push("Warning: It seems like the app does not have access to your Shared Folder. This permission is needed for the app to properly allow you to backup & restore the database. If you leave this permission off, some features may not work properly. Select the icon to launch the Application Permissions screen where you can turn these settings on.");
                allIcons.push("images/toast/no_shared_folder.png");
            }
            
            if ( !persist.hasPhoneControlAccess() ) {
                allMessages.push("Warning: It seems like the app does not have access to control your phone. This permission is needed for the app to access the phone service required to be able to block calls based on the incoming number. Select the icon to launch the Application Permissions screen where you can turn these settings on.");
                allIcons.push("images/toast/no_phone_control.png");
            }
            
            if (allMessages.length > 0)
            {
                logTab.content.permissionToast.messages = allMessages;
                logTab.content.permissionToast.icons = allIcons;
                logTab.content.permissionToast.delegateActive = true;
            }
            
            tutorial.execAppMenu();
        }
    }
    
    Tab
    {
        id: logTab
        title: qsTr("Logs") + Retranslate.onLanguageChanged
        description: qsTr("Blocked Messages") + Retranslate.onLanguageChanged
        imageSource: "images/tabs/ic_logs.png"
        delegateActivationPolicy: TabDelegateActivationPolicy.ActivateWhenSelected
        
        delegate: Delegate {
            source: "LogPane.qml"
        }
        
        function onDataLoaded(id, data)
        {
            if (id == QueryId.FetchAllLogs) {
                unreadContentCount = data.length;
            } else if (id == QueryId.FetchLatestLogs) {
                unreadContentCount = unreadContentCount + data.length;
            }
        }
        
        onCreationCompleted: {
            helper.dataReady.connect(onDataLoaded);
        }
        
        onTriggered: {
            console.log("UserEvent: LogTabTriggered");
        }
    }
    
    Tab {
        id: blockedTab
        title: qsTr("Blocked") + Retranslate.onLanguageChanged
        description: qsTr("Blocked List") + Retranslate.onLanguageChanged
        imageSource: "images/tabs/ic_blocked.png"
        delegateActivationPolicy: TabDelegateActivationPolicy.ActivateWhenSelected
        
        delegate: Delegate
        {
            source: "BlockedSenderPane.qml"
            
            function onAddClicked() {
                conversationsTab.triggered();
                activeTab = conversationsTab;
            }
            
            onObjectChanged: {
                if (active) {
                    object.addClicked.connect(onAddClicked);
                }
            }
        }
        
        onTriggered: {
            console.log("UserEvent: BlockedTabTriggered");
        }
    }
    
    Tab {
        id: conversationsTab
        title: qsTr("Conversations") + Retranslate.onLanguageChanged
        description: qsTr("Potential Spam Messages") + Retranslate.onLanguageChanged
        imageSource: "images/tabs/ic_conversations.png"
        delegateActivationPolicy: TabDelegateActivationPolicy.ActivateWhenSelected
        
        delegate: Delegate {
            source: "ConversationsPane.qml"
        }
        
        onTriggered: {
            console.log("UserEvent: ConversationsTabTriggered");
        }
    }
    
    Tab {
        id: keywordsTab
        title: qsTr("Keywords") + Retranslate.onLanguageChanged
        description: qsTr("Blacklisted Keywords") + Retranslate.onLanguageChanged
        imageSource: "images/tabs/ic_keywords.png"
        delegateActivationPolicy: TabDelegateActivationPolicy.ActivateWhenSelected
        
        delegate: Delegate {
            source: "BlockedKeywordPane.qml"
        }
        
        onTriggered: {
            console.log("UserEvent: KeywordsTabTriggered");
        }
    }
}