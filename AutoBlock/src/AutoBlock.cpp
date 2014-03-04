#include "precompiled.h"

#include "AutoBlock.hpp"
#include "AccountImporter.h"
#include "BlockUtils.h"
#include "InvocationUtils.h"
#include "IOUtils.h"
#include "KeywordParserThread.h"
#include "LocaleUtil.h"
#include "Logger.h"
#include "MessageFetcherThread.h"
#include "MessageImporter.h"
#include "QueryId.h"

namespace autoblock {

using namespace bb::cascades;
using namespace canadainc;

AutoBlock::AutoBlock(Application* app) :
        QObject(app), m_cover("Cover.qml"), m_helper(&m_sql), m_importer(NULL)
{
    switch ( m_invokeManager.startupMode() )
    {
    case ApplicationStartupMode::InvokeCard:
        connect( &m_invokeManager, SIGNAL( invoked(bb::system::InvokeRequest const&) ), this, SLOT( invoked(bb::system::InvokeRequest const&) ) );
        connect( &m_invokeManager, SIGNAL( childCardDone(bb::system::CardDoneMessage const&) ), this, SLOT( childCardDone(bb::system::CardDoneMessage const&) ) );
        break;

    default:
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
        LOGGER("========= INVOKED DATA" << tokens);

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
    finishWithToast( tr("The following keywords were added: %1").arg( keywordsList.join(", ") ) );
}


void AutoBlock::finishWithToast(QString const& message)
{
    m_persistance.showBlockingToast(message);
    m_invokeManager.sendCardDone( CardDoneMessage() );
}


void AutoBlock::parseKeywords(QVariantList const& toProcess)
{
    KeywordParserThread* ai = new KeywordParserThread(toProcess);
    connect( ai, SIGNAL( keywordsExtracted(QStringList const&) ), this, SLOT( onKeywordsExtracted(QStringList const&) ) );
    IOUtils::startThread(ai);
}


void AutoBlock::messageFetched(QVariantMap const& result)
{
    LOGGER("Message fetched" << result);

    QVariantList toProcess;
    toProcess << result;

    QStringList added = m_helper.block(toProcess);
    m_persistance.showToast( tr("The following addresses were blocked: %1").arg( added.join(", ") ) );

    parseKeywords(toProcess);
}


void AutoBlock::onKeywordsExtracted(QStringList const& keywords)
{
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

    checkDatabase();

    QmlDocument* qml = QmlDocument::create("asset:///"+qmlSource).parent(this);
    qml->setContextProperty("app", this);
    qml->setContextProperty("helper", &m_helper);
    qml->setContextProperty("persist", &m_persistance);

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

	connect( &m_update, SIGNAL( updatesAvailable(QStringList const&) ), this, SIGNAL( updatesAvailable(QStringList const&) ) );
	connect( Application::instance(), SIGNAL( aboutToQuit() ), this, SLOT( terminateThreads() ) );

    InvokeRequest request;
    request.setTarget("com.canadainc.AutoBlockService");
    request.setAction("com.canadainc.AutoBlockService.RESET");
    m_invokeManager.invoke(request);

    InvocationUtils::validateEmailSMSAccess( tr("Warning: It seems like the app does not have access to your Email/SMS messages Folder. This permission is needed for the app to access the SMS and email services it needs to do the filtering of the spam messages. If you leave this permission off, some features may not work properly. Select OK to launch the Application Permissions screen where you can turn these settings on.") );
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


void AutoBlock::settingChanged(QString const& key)
{
	LOGGER(key);

	if (key == "account") {
		LOGGER("Accounts elected changed");
		emit accountSelectedChanged();
	}
}


void AutoBlock::checkDatabase()
{
	QString database = BlockUtils::databasePath();

	if ( QFile::exists(database) )
	{
	    m_sql.setSource(database);

		connect( &m_updateWatcher, SIGNAL( fileChanged(QString const&) ), this, SLOT( databaseUpdated(QString const&) ) );
		m_updateWatcher.addPath(database);

		portClassic();
	} else {
		LOGGER("Database does not exist");
		static int count = 0;
		recheck( count, SLOT( checkDatabase() ) );
	}
}


void AutoBlock::portClassic()
{
    if ( m_persistance.contains("blockedList") )
    {
        QVariantMap map = m_persistance.getValueFor("blockedList").toMap();
        QStringList accounts = map.keys();
        QVariantList toBlock;

        for (int i = accounts.size()-1; i >= 0; i--)
        {
            QVariantList addresses = map.value(accounts[i]).toList();

            for (int j = addresses.size()-1; j >= 0; j--)
            {
                QVariantMap q;
                q["senderAddress"] = addresses[j];

                toBlock << q;
            }
        }

        m_helper.block(toBlock);
        m_persistance.remove("blockedList");
    }
}


void AutoBlock::recheck(int &count, const char* slotName)
{
	LOGGER("Database does not exist");
	++count;

	if (count < 5) {
		LOGGER("Retrying" << count);
		QTimer::singleShot(2000*count, this, slotName);
	} else {
		LOGGER("Can't connect...");
		m_persistance.showToast( tr("Error initializing link with service. Please restart your device...") );
	}
}


void AutoBlock::databaseUpdated(QString const& path)
{
	Q_UNUSED(path);

	LOGGER("Database updated!");
	m_helper.fetchLatestLogs();
}


void AutoBlock::loadAccounts()
{
	AccountImporter* ai = new AccountImporter();
	connect( ai, SIGNAL( importCompleted(QVariantList const&) ), this, SIGNAL( accountsImported(QVariantList const&) ) );
	IOUtils::startThread(ai);
}


void AutoBlock::loadMessages(qint64 accountId)
{
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


bool AutoBlock::accountSelected() {
	LOGGER( m_persistance.contains("account") );
	return m_persistance.contains("account");
}


void AutoBlock::extractKeywords(QVariantList const& messages)
{
    LOGGER("Extract keywords: " << messages);
    KeywordParserThread* kpt = new KeywordParserThread(messages);
    connect( kpt, SIGNAL( keywordsExtracted(QStringList const&) ), this, SIGNAL( keywordsExtracted(QStringList const&) ) );
    IOUtils::startThread(kpt);
}


void AutoBlock::childCardDone(bb::system::CardDoneMessage const& message) {
    m_invokeManager.sendCardDone(message);
}


QString AutoBlock::validateKeyword(QString const& keyword)
{
    LOGGER(keyword);
    return BlockUtils::isValidKeyword(keyword);
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
