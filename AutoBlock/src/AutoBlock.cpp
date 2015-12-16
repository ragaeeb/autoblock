#include "precompiled.h"

#include "AutoBlock.hpp"
#include "AppLogFetcher.h"
#include "BlockUtils.h"
#include "CardUtils.h"
#include "IOUtils.h"
#include "JlCompress.h"
#include "InvocationUtils.h"
#include "KeywordParserThread.h"
#include "LocaleUtil.h"
#include "Logger.h"
#include "MessageFetcherThread.h"
#include "TextUtils.h"
#include "ThreadUtils.h"

#define TARGET_BLOCK_EMAIL "com.canadainc.AutoBlock.reply"
#define TARGET_PLAIN_TEXT "com.canadainc.AutoBlock.sharehandler"

namespace autoblock {

using namespace bb::cascades;
using namespace bb::system;
using namespace canadainc;

AutoBlock::AutoBlock(InvokeManager* i) :
        m_cover( i->startupMode() != ApplicationStartupMode::InvokeCard, this ),
        m_persistance(i),
        m_helper(&m_persistance), m_update(&m_helper),
        m_payment(&m_persistance), m_root(NULL), m_offloader(&m_persistance)
{
    switch ( m_invokeManager.startupMode() )
    {
    case ApplicationStartupMode::InvokeCard:
        connect( i, SIGNAL( cardPooled(bb::system::CardDoneMessage const&) ), QCoreApplication::instance(), SLOT( quit() ) );
        connect( i, SIGNAL( invoked(bb::system::InvokeRequest const&) ), this, SLOT( invoked(bb::system::InvokeRequest const&) ) );
        break;

    default:
        initRoot();
        break;
    }

    connect( &m_invokeManager, SIGNAL( childCardDone(bb::system::CardDoneMessage const&) ), this, SLOT( childCardDone(bb::system::CardDoneMessage const&) ) );
}


void AutoBlock::initRoot(QString const& qmlDoc)
{
    qmlRegisterUncreatableType<QueryId>("com.canadainc.data", 1, 0, "QueryId", "Can't instantiate");

    QDeclarativeContext* rootContext = QmlDocument::defaultDeclarativeEngine()->rootContext();
    rootContext->setContextProperty("offloader", &m_offloader );

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
    disconnect( this, SIGNAL( initialize() ), this, SLOT( lazyInit() ) ); // in case we get invoked again

    INIT_SETTING("keywordThreshold", 2);
    INIT_SETTING("whitelistContacts", 1);
    INIT_SETTING("ignorePunctuation", 1);

    AppLogFetcher::create( &m_persistance, &ThreadUtils::compressFiles, this );
    m_offloader.lazyInit();
    m_update.lazyInit();
    m_helper.lazyInit();

    m_update.invokeService();
    m_cover.setContext("helper", &m_helper);

    QmlDocument* qml = QmlDocument::create("asset:///NotificationToast.qml").parent(this);
    QObject* toast = qml->createRootObject<QObject>();
    QmlDocument::defaultDeclarativeEngine()->rootContext()->setContextProperty("toaster", toast);

    DeviceUtils::registerTutorialTips(this);

    if ( !m_helper.checkDatabase() ) {
        connect( &m_helper, SIGNAL( readyChanged() ), this, SLOT( completeInvoke() ) );
    }

    //emit lazyInitComplete();
    testX();
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
    QStringList keywordsList = m_helper.blockKeywords(this, keywords);

    if ( keywordsList.isEmpty() ) {
        finishWithToast( tr("The keyword(s) could not be added.") );
    }
}


void AutoBlock::finishWithToast(QString const& message)
{
    m_persistance.showBlockingDialog( tr("Auto Block"), message, tr("OK"), "" );
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

    m_helper.fetchExcludedWords(ai);
}


void AutoBlock::messageFetched(QVariantMap const& result)
{
    LOGGER(result);

    if ( !result.isEmpty() )
    {
        QVariantList toProcess;
        toProcess << result;

        QStringList added = m_helper.block(this, toProcess);

        if ( added.isEmpty() ) {
            m_persistance.showToast( tr("The addresses could not be blocked. This most likely means the spammers sent the message anonimously. In this case you will have to block by keywords instead. If this is not the case, we suggest filing a bug-report!"), "asset:///images/tabs/ic_blocked.png" );
        }

        parseKeywords(toProcess);
    } else {
        LOGGER("[FAILEDHUBBLOCK]");
        m_persistance.showToast( tr("Could not block the sender, this is due to a bug in BlackBerry OS 10.2.1. There are two ways around this problem:\n\n1) From the BlackBerry Hub, tap on the email to open it, tap on the menu icon (...) on the bottom-right, choose Share, and then choose Auto Block.\n\n2) Open the app and block the message from the Conversations tab."), "asset:///images/ic_pim_warning.png" );
    }
}


void AutoBlock::onDataLoaded(int id, QVariant data)
{
    Q_UNUSED(data);

    if (id == QueryId::BlockSenders) {
        m_persistance.showToast( tr("Successfully blocked addresses!"), "images/menu/ic_blocked_user.png" );
    } else if (id == QueryId::BlockKeywords) {
        finishWithToast( tr("The keywords were successfully added!") );
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


void AutoBlock::extractKeywords(QVariantList const& messages)
{
    LOGGER(messages);
    prepareKeywordExtraction( messages, SIGNAL( keywordsExtracted(QVariantList const&) ) );
}


void AutoBlock::childCardDone(bb::system::CardDoneMessage const& message)
{
    LOGGER( message.reason() );

    if ( !message.data().isEmpty() ) {
        m_persistance.invokeManager()->sendCardDone(message);
    }
}


void AutoBlock::forceSetup() {
    m_update.invokeService("setup");
}


void AutoBlock::exitAfterRestore()
{
    LOGGER("Terminating...");
    m_persistance.showBlockingDialog( tr("Exit"), tr("Successfully restored! The app will now close itself so when you re-open it the restored database can take effect!"), tr("OK"), "" );
    Application::instance()->requestExit();
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
