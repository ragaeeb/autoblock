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
            tutorial.execAppMenu();
            
            if (helper.ready) {
                setupComplete();
            } else {
                helper.readyChanged.connect(setupComplete);
                
                definition.source = "SetupDialog.qml";
                var setup = definition.createObject();
                setup.open();
            }
        }
    }
    
    function setupComplete()
    {
        logTab.delegateActivationPolicy = TabDelegateActivationPolicy.ActivateWhenSelected;
        
        if ( persist.getValueFor("startAtConversations") == 1 ) {
            activeTab = conversationsTab;
        }
    }
    
    Tab
    {
        id: logTab
        title: qsTr("Logs") + Retranslate.onLanguageChanged
        description: qsTr("Blocked Messages") + Retranslate.onLanguageChanged
        imageSource: "images/tabs/ic_logs.png"
        delegateActivationPolicy: TabDelegateActivationPolicy.None
        
        delegate: Delegate {
            source: "LogPane.qml"
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
    
    attachedObjects: [
        ComponentDefinition {
            id: definition
        }
    ]
}