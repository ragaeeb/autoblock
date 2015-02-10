#include "precompiled.h"

#include "AutoBlock.hpp"
#include "AccountImporter.h"
#include "AppLogFetcher.h"
#include "BlockUtils.h"
#include "CardUtils.h"
#include "IOUtils.h"
#include "JlCompress.h"
#include "InvocationUtils.h"
#include "KeywordParserThread.h"
#include "LocaleUtil.h"
#include "Logger.h"
#include "LogMonitor.h"
#include "MessageFetcherThread.h"
#include "MessageImporter.h"
#include "TextUtils.h"

#define CARD_LOG_FILE QString("%1/logs/card.log").arg( QDir::currentPath() )
#define TARGET_BLOCK_EMAIL "com.canadainc.AutoBlock.reply"
#define TARGET_PLAIN_TEXT "com.canadainc.AutoBlock.sharehandler"

namespace {

void compressFiles(QSet<QString>& attachments)
{
    attachments << CARD_LOG_FILE;
    attachments << DATABASE_PATH;
    attachments << SERVICE_LOG_FILE;
    canadainc::AppLogFetcher::removeInvalid(attachments);

    JlCompress::compressFiles( ZIP_FILE_PATH, attachments.toList() );

    QFile::remove(CARD_LOG_FILE);
    QFile::remove(SERVICE_LOG_FILE);
}

}

namespace autoblock {

using namespace bb::cascades;
using namespace canadainc;

AutoBlock::AutoBlock(Application* app) :
        QObject(app), m_cover("Cover.qml"),
        m_helper(&m_sql, &m_persistance), m_importer(NULL), m_update(&m_helper), m_payment(&m_persistance), m_root(NULL)
{
    INIT_SETTING(CARD_KEY, true);
    INIT_SETTING(UI_KEY, true);
    INIT_SETTING(SERVICE_KEY, false);
    INIT_SETTING("days", 7);

    switch ( m_invokeManager.startupMode() )
    {
    case ApplicationStartupMode::InvokeCard:
        LogMonitor::create(CARD_KEY, CARD_LOG_FILE, this);
        connect( &m_invokeManager, SIGNAL( cardPooled(bb::system::CardDoneMessage const&) ), app, SLOT( quit() ) );
        connect( &m_invokeManager, SIGNAL( childCardDone(bb::system::CardDoneMessage const&) ), this, SLOT( childCardDone(bb::system::CardDoneMessage const&) ) );
        connect( &m_invokeManager, SIGNAL( invoked(bb::system::InvokeRequest const&) ), this, SLOT( invoked(bb::system::InvokeRequest const&) ) );
        break;

    default:
        LogMonitor::create(UI_KEY, UI_LOG_FILE, this);
        initRoot();
        break;
    }
}


void AutoBlock::initRoot(QString const& qmlDoc)
{
    qmlRegisterUncreatableType<QueryId>("com.canadainc.data", 1, 0, "QueryId", "Can't instantiate");

    QMap<QString, QObject*> context;
    context.insert("helper", &m_helper);
    context.insert("payment", &m_payment);
    context.insert("updater", &m_update);

    m_root = CardUtils::initAppropriate(qmlDoc, context, this);
    emit initialize();
}


void AutoBlock::invoked(bb::system::InvokeRequest const& request)
{
    QString target = request.target();

    LOGGER( request.action() << target << request.mimeType() << request.metadata() << request.uri().toString() << QString( request.data() ) );

    QMap<QString,QString> targetToQML;
    targetToQML[TARGET_BLOCK_EMAIL] = "ElementPickerPage.qml";
    targetToQML[TARGET_PLAIN_TEXT] = "ElementPickerPage.qml";

    QString qml = targetToQML.value(target);

    if ( qml.isNull() ) {
        qml = "LogPane.qml";
    }

    initRoot(qml);

    m_request = request;
}


void AutoBlock::lazyInit()
{
    INIT_SETTING("keywordThreshold", 3);
    INIT_SETTING("whitelistContacts", 1);

    qmlRegisterType<bb::cascades::pickers::FilePicker>("bb.cascades.pickers", 1, 0, "FilePicker");
    qmlRegisterUncreatableType<bb::cascades::pickers::FileType>("bb.cascades.pickers", 1, 0, "FileType", "Can't instantiate");
    qmlRegisterUncreatableType<bb::cascades::pickers::FilePickerMode>("bb.cascades.pickers", 1, 0, "FilePickerMode", "Can't instantiate");

    InvokeRequest request;
    request.setTarget("com.canadainc.AutoBlockService");
    request.setAction("com.canadainc.AutoBlockService.RESET");
    m_invokeManager.invoke(request);

    connect( Application::instance(), SIGNAL( aboutToQuit() ), this, SLOT( terminateThreads() ) );

    m_cover.setContext("helper", &m_helper);

    AppLogFetcher::create( &m_persistance, &compressFiles, this );

    QString target = m_request.target();

    if ( !target.isNull() )
    {
        bool ready = m_helper.checkDatabase();

        if (ready) {
            completeInvoke();
        } else {
            connect( &m_helper, SIGNAL( readyChanged() ), this, SLOT( completeInvoke() ) );
        }
    }

    QmlDocument* qml = QmlDocument::create("asset:///NotificationToast.qml").parent(this);
    QObject* toast = qml->createRootObject<QObject>();
    QmlDocument::defaultDeclarativeEngine()->rootContext()->setContextProperty("tutorialToast", toast);

    emit lazyInitComplete();
}


void AutoBlock::completeInvoke()
{
    connect( m_root, SIGNAL( elementsSelected(QVariant) ), this, SLOT( onKeywordsSelected(QVariant) ) );

    QString target = m_request.target();

    if (target == TARGET_BLOCK_EMAIL)
    {
        QByteArray data = m_request.data();

        MessageFetcherThread* ai = new MessageFetcherThread( data, m_request.uri().toString(), this );
        connect( ai, SIGNAL( messageFetched(QVariantMap const&) ), this, SLOT( messageFetched(QVariantMap const&) ) );
        IOUtils::startThread(ai);
    } else if (target == TARGET_PLAIN_TEXT) {
        QString result = QString::fromUtf8( m_request.data().constData() );

        QVariantMap map;
        map["text"] = result;
        parseKeywords( QVariantList() << map );
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
    m_persistance.showBlockingToast( message, "", "asset:///images/ic_steps.png" );
    m_invokeManager.sendCardDone( CardDoneMessage() );
}


void AutoBlock::parseKeywords(QVariantList const& toProcess)
{
    LOGGER(toProcess);

    prepareKeywordExtraction( toProcess, SLOT( onKeywordsExtracted(QVariantList const&) ) );
}


void AutoBlock::prepareKeywordExtraction(QVariantList const& toProcess, const char* slot)
{
    KeywordParserThread* ai = new KeywordParserThread( toProcess, m_persistance.getValueFor("ignorePunctuation") == 1 );
    connect( ai, SIGNAL( keywordsExtracted(QVariantList const&) ), this, slot );
    connect( &m_helper, SIGNAL( dataReady(int, QVariant const&) ), ai, SLOT( dataReady(int, QVariant const&) ) );

    m_helper.fetchExcludedWords();
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
            m_persistance.showToast( tr("The following addresses were blocked: %1").arg( added.join(", ") ), "", "asset:///images/menu/ic_blocked_user.png" );
        } else {
            m_persistance.showToast( tr("The addresses could not be blocked. This most likely means the spammers sent the message anonimously. In this case you will have to block by keywords instead. If this is not the case, we suggest filing a bug-report!"), "", "asset:///images/tabs/ic_blocked.png" );
        }

        parseKeywords(toProcess);
    } else {
        LOGGER("[FAILEDHUBBLOCK]");
        m_persistance.showToast( tr("Could not block the sender, this is due to a bug in BlackBerry OS 10.2.1. There are two ways around this problem:\n\n1) From the BlackBerry Hub, tap on the email to open it, tap on the menu icon (...) on the bottom-right, choose Share, and then choose Auto Block.\n\n2) Open the app and block the message from the Conversations tab."), "", "asset:///images/ic_pim_warning.png" );
    }
}


void AutoBlock::onKeywordsExtracted(QVariantList const& keywords)
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
	AccountImporter* ai = new AccountImporter(Service::Messages, true);
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
    prepareKeywordExtraction( messages, SIGNAL( keywordsExtracted(QVariantList const&) ) );
}


void AutoBlock::childCardDone(bb::system::CardDoneMessage const& message)
{
    LOGGER( message.reason() );
    m_invokeManager.sendCardDone(message);
}


QString AutoBlock::renderStandardTime(QDateTime const& theTime) {
    return LocaleUtil::renderStandardTime(theTime);
}


void AutoBlock::forceSetup()
{
    InvokeRequest request;
    request.setTarget("com.canadainc.AutoBlockService");
    request.setAction("com.canadainc.AutoBlockService.RESET");
    request.setData( QString("setup").toAscii() );
    m_invokeManager.invoke(request);
}


void AutoBlock::exitAfterRestore()
{
    LOGGER("Terminating...");
    m_persistance.showBlockingDialog( tr("Exit"), tr("Successfully restored! The app will now close itself so when you re-open it the restored database can take effect!"), tr("OK"), "" );
    Application::instance()->quit();
}


void AutoBlock::invokeService(QString const& senderAddress, QString const& senderName, QString const& body)
{
    LOGGER(senderAddress << senderName << body);

    InvokeRequest request;
    request.setTarget("com.canadainc.AutoBlockService");
    request.setAction("com.canadainc.AutoBlockService.RESET");
    request.setData( QString("test").toAscii() );

    QVariantMap data;
    data["address"] = senderAddress;
    data["body"] = body;
    data["name"] = senderName;
    request.setMetadata(data);

    m_invokeManager.invoke(request);
}


QString AutoBlock::bytesToSize(qint64 size) {
    return TextUtils::bytesToSize(size);
}


AutoBlock::~AutoBlock()
{
}

}
