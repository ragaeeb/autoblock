#include "precompiled.h"

#include "AutoBlock.hpp"
#include "AccountImporter.h"
#include "AutoBlockCollector.h"
#include "BlockUtils.h"
#include "IOUtils.h"
#include "KeywordParserThread.h"
#include "LocaleUtil.h"
#include "Logger.h"
#include "LogMonitor.h"
#include "MessageFetcherThread.h"
#include "MessageImporter.h"
#include "PimUtil.h"

#define CARD_KEY "logCard"

namespace autoblock {

using namespace bb::cascades;
using namespace canadainc;

AutoBlock::AutoBlock(Application* app) :
        QObject(app), m_cover("Cover.qml"), m_reporter( new AutoBlockCollector() ), m_helper(&m_sql, &m_reporter), m_importer(NULL)
{
    INIT_SETTING(CARD_KEY, true);
    INIT_SETTING(UI_KEY, true);
    INIT_SETTING(SERVICE_KEY, false);

    switch ( m_invokeManager.startupMode() )
    {
    case ApplicationStartupMode::InvokeCard:
        m_logMonitor = new LogMonitor(CARD_KEY, CARD_LOG_FILE, this);
        connect( &m_invokeManager, SIGNAL( invoked(bb::system::InvokeRequest const&) ), this, SLOT( invoked(bb::system::InvokeRequest const&) ) );
        connect( &m_invokeManager, SIGNAL( childCardDone(bb::system::CardDoneMessage const&) ), this, SLOT( childCardDone(bb::system::CardDoneMessage const&) ) );
        break;

    default:
        m_logMonitor = new LogMonitor(UI_KEY, UI_LOG_FILE, this);
        initRoot();
        break;
    }
}


void AutoBlock::invoked(bb::system::InvokeRequest const& request)
{
    LOGGER("Invoked" << request.uri() << request.mimeType() << request.action() << request.target());
    bool ok = false;

    if ( request.target().compare("com.canadainc.AutoBlock.reply", Qt::CaseInsensitive) == 0 )
    {
        QStringList tokens = request.uri().toString().split(":");
        LOGGER("INVOKED DATA" << tokens);

        if ( tokens.size() > 3 )
        {
            QObject* root = initRoot("ElementPickerPage.qml", true);
            connect( root, SIGNAL( elementsSelected(QVariant) ), this, SLOT( onKeywordsSelected(QVariant) ) );

            MessageFetcherThread* ai = new MessageFetcherThread(tokens);
            connect( ai, SIGNAL( messageFetched(QVariantMap const&) ), this, SLOT( messageFetched(QVariantMap const&) ) );
            IOUtils::startThread(ai);

            ok = true;
        }
    } else if ( request.target().compare("com.canadainc.AutoBlock.sharehandler", Qt::CaseInsensitive) == 0 ) {
        QString mime = request.mimeType();

        if (mime == "text/plain")
        {
            QObject* root = initRoot("ElementPickerPage.qml", true);
            connect( root, SIGNAL( elementsSelected(QVariant) ), this, SLOT( onKeywordsSelected(QVariant) ) );
            QString result = QString::fromUtf8( request.data().constData() );

            QVariantMap map;
            map["text"] = result;
            parseKeywords( QVariantList() << map );

            ok = true;
        }
    }

    if (!ok) {
        initRoot();
    }
}


void AutoBlock::onKeywordsSelected(QVariant k)
{
    QVariantList keywords = k.toList();
    QStringList keywordsList = m_helper.blockKeywords(keywords);

    if ( !keywordsList.isEmpty() ) {
        finishWithToast( tr("The following keywords were added: %1").arg( keywordsList.join(", ") ) );
    } else {
        finishWithToast( tr("The keyword(s) could not be added.") );
    }
}


void AutoBlock::finishWithToast(QString const& message)
{
    m_persistance.showBlockingToast(message);
    m_invokeManager.sendCardDone( CardDoneMessage() );
}


void AutoBlock::parseKeywords(QVariantList const& toProcess)
{
    LOGGER(toProcess);

    KeywordParserThread* ai = new KeywordParserThread(toProcess);
    connect( ai, SIGNAL( keywordsExtracted(QStringList const&) ), this, SLOT( onKeywordsExtracted(QStringList const&) ) );
    IOUtils::startThread(ai);
}


void AutoBlock::messageFetched(QVariantMap const& result)
{
    LOGGER(result);

    if ( !result.isEmpty() )
    {
        QVariantList toProcess;
        toProcess << result;

        QStringList added = m_helper.block(toProcess);

        if ( !added.isEmpty() ) {
            m_persistance.showToast( tr("The following addresses were blocked: %1").arg( added.join(", ") ), "", "asset:///images/ic_blocked_user.png" );
        } else {
            m_persistance.showToast( tr("The addresses could not be blocked."), "", "asset:///images/tabs/ic_blocked.png" );
        }

        parseKeywords(toProcess);
    } else {
        LOGGER("*** FAILED HUB BLOCK!");
        m_persistance.showToast( tr("Could not block the sender, this is due to a bug in BlackBerry OS 10.2.1. There are two ways around this problem:\n\n1) From the BlackBerry Hub, tap on the email to open it, tap on the menu icon (...) on the bottom-right, choose Share, and then choose Auto Block.\n\n2) Open the app and block the message from the Conversations tab."), "", "asset:///images/ic_pim_warning.png" );
    }
}


void AutoBlock::onKeywordsExtracted(QStringList const& keywords)
{
    LOGGER(keywords);

    if ( !keywords.isEmpty() )
    {
        NavigationPane* root = static_cast<NavigationPane*>( Application::instance()->scene() );
        root->top()->setProperty("elements", keywords);
    } else {
        finishWithToast( tr("Could not find any suspicious keywords in the message...") );
    }
}


QObject* AutoBlock::initRoot(QString const& qmlSource, bool invoked)
{
    m_cover.setContext("helper", &m_helper);

    qmlRegisterType<canadainc::LocaleUtil>("com.canadainc.data", 1, 0, "LocaleUtil");
    qmlRegisterUncreatableType<QueryId>("com.canadainc.data", 1, 0, "QueryId", "Can't instantiate");

    m_helper.checkDatabase();

    QmlDocument* qml = QmlDocument::create("asset:///"+qmlSource).parent(this);
    qml->setContextProperty("app", this);
    qml->setContextProperty("helper", &m_helper);
    qml->setContextProperty("persist", &m_persistance);
    qml->setContextProperty("updater", &m_update);
    qml->setContextProperty("reporter", &m_reporter);

    AbstractPane* root = qml->createRootObject<AbstractPane>();
    Application::instance()->setScene(root);

    if (invoked) {
        Page* r = qml->createRootObject<Page>();
        NavigationPane* np = NavigationPane::create().backButtons(true);
        np->push(r);
        Application::instance()->setScene(np);

        root = r;
    } else {
        root = qml->createRootObject<AbstractPane>();
        Application::instance()->setScene(root);
    }

    connect( this, SIGNAL( initialize() ), this, SLOT( init() ), Qt::QueuedConnection ); // async startup

    emit initialize();

    return root;
}


void AutoBlock::init()
{
	INIT_SETTING("days", 7);
	INIT_SETTING("keywordThreshold", 3);
	INIT_SETTING("whitelistContacts", 1);

	qmlRegisterType<bb::device::DisplayInfo>("bb.device", 1, 0, "DisplayInfo");

	connect( Application::instance(), SIGNAL( aboutToQuit() ), this, SLOT( terminateThreads() ) );

    InvokeRequest request;
    request.setTarget("com.canadainc.AutoBlockService");
    request.setAction("com.canadainc.AutoBlockService.RESET");
    m_invokeManager.invoke(request);

    PimUtil::validateEmailSMSAccess( tr("Warning: It seems like the app does not have access to your Email/SMS messages Folder. This permission is needed for the app to access the SMS and email services it needs to do the filtering of the spam messages. If you leave this permission off, some features may not work properly. Select OK to launch the Application Permissions screen where you can turn these settings on.") );

    if ( !m_persistance.contains("clearedNulls") ) {
        m_helper.cleanInvalidEntries();
        m_persistance.saveValueFor("clearedNulls", 1, false);
    }
}


void AutoBlock::terminateThreads()
{
    if (m_importer) {
        m_importer->cancel();
    }
}


void AutoBlock::create(Application* app) {
	new AutoBlock(app);
}


void AutoBlock::loadAccounts()
{
	AccountImporter* ai = new AccountImporter();
	connect( ai, SIGNAL( importCompleted(QVariantList const&) ), this, SIGNAL( accountsImported(QVariantList const&) ) );
	IOUtils::startThread(ai);
}


void AutoBlock::loadMessages(qint64 accountId)
{
    LOGGER(accountId);
    terminateThreads();

    m_importer = new MessageImporter(accountId);
    m_importer->setTimeLimit( m_persistance.getValueFor("days").toInt() );

    connect( m_importer, SIGNAL( importCompleted(QVariantList const&) ), this, SLOT( onMessagesImported(QVariantList const&) ) );
    connect( m_importer, SIGNAL( progress(int, int) ), this, SIGNAL( loadProgress(int, int) ) );

	IOUtils::startThread(m_importer);
}


void AutoBlock::onMessagesImported(QVariantList const& qvl)
{
    emit messagesImported(qvl);
    m_importer = NULL;
}


void AutoBlock::extractKeywords(QVariantList const& messages)
{
    LOGGER(messages);
    KeywordParserThread* kpt = new KeywordParserThread(messages);
    connect( kpt, SIGNAL( keywordsExtracted(QStringList const&) ), this, SIGNAL( keywordsExtracted(QStringList const&) ) );
    IOUtils::startThread(kpt);
}


void AutoBlock::childCardDone(bb::system::CardDoneMessage const& message) {
    m_invokeManager.sendCardDone(message);
}


void AutoBlock::submit(QObject* gdm)
{
    GroupDataModel* g = qobject_cast<GroupDataModel*>(gdm);
    m_update.submit( g->toListOfMaps() );
}


AutoBlock::~AutoBlock()
{
}

}
