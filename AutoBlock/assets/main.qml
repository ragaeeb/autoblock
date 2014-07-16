import bb.cascades 1.2
import com.canadainc.data 1.0

TabbedPane
{
    id: root
    activeTab: logTab
    showTabsOnActionBar: true
    
    Menu.definition: CanadaIncMenu
    {
        labelColor: Color.Black
        projectName: "autoblock"
        showServiceLogging: true
        showSubmitLogs: true
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
    }
    
    function onReady()
    {
        if ( persist.getValueFor("startAtConversations") == 1 ) {
            activeTab = conversationsTab;
        }
    }
    
    onCreationCompleted: {
        app.lazyInitComplete.connect(onReady);
    }
}