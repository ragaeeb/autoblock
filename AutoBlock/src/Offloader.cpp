#include "precompiled.h"

#include "Offloader.h"
#include "AccountImporter.h"
#include "BlockUtils.h"
#include "IOUtils.h"
#include "Logger.h"
#include "MessageImporter.h"
#include "Persistance.h"
#include "ThreadUtils.h"

namespace autoblock {

using namespace bb::cascades;
using namespace canadainc;

Offloader::Offloader(Persistance* persist) :
        m_timeRender(bb::system::LocaleType::Region), m_importer(NULL), m_persist(persist)
{
}


void Offloader::loadAccounts()
{
    AccountImporter* ai = new AccountImporter(Service::Messages, true);
    connect( ai, SIGNAL( importCompleted(QVariantList const&) ), this, SIGNAL( accountsImported(QVariantList const&) ) );
    IOUtils::startThread(ai);
}


void Offloader::loadMessages(qint64 accountId)
{
    LOGGER(accountId);
    terminateThreads();

    m_importer = new MessageImporter(accountId);
    m_importer->setTimeLimit( m_persist->getValueFor("days").toInt() );

    connect( m_importer, SIGNAL( importCompleted(QVariantList const&) ), this, SLOT( onMessagesImported(QVariantList const&) ) );
    connect( m_importer, SIGNAL( progress(int, int) ), this, SIGNAL( loadProgress(int, int) ) );

    IOUtils::startThread(m_importer);
}


void Offloader::onMessagesImported(QVariantList const& qvl)
{
    emit messagesImported(qvl);
    m_importer = NULL;
}


QString Offloader::renderStandardTime(QDateTime const& theTime)
{
    static QString format = bb::utility::i18n::timeFormat(bb::utility::i18n::DateFormat::Short);
    return m_timeRender.locale().toString(theTime, format);
}


void Offloader::lazyInit() {
    connect( Application::instance(), SIGNAL( aboutToQuit() ), this, SLOT( terminateThreads() ) );
}


void Offloader::terminateThreads()
{
    if (m_importer) {
        m_importer->cancel();
    }
}


Offloader::~Offloader()
{
}

} /* namespace autoblock */
