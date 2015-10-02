#include "precompiled.h"

#include "Offloader.h"
#include "AccountImporter.h"
#include "IOUtils.h"
#include "Logger.h"
#include "BlockUtils.h"
#include "ThreadUtils.h"

namespace autoblock {

using namespace canadainc;

Offloader::Offloader() :
        m_timeRender(bb::system::LocaleType::Region)
{
}


void Offloader::loadAccounts()
{
    AccountImporter* ai = new AccountImporter(Service::Calendars);
    connect( ai, SIGNAL( importCompleted(QVariantList const&) ), this, SIGNAL( accountsImported(QVariantList const&) ) );
    IOUtils::startThread(ai);
}


QString Offloader::renderStandardTime(QDateTime const& theTime)
{
    static QString format = bb::utility::i18n::timeFormat(bb::utility::i18n::DateFormat::Short);
    return m_timeRender.locale().toString(theTime, format);
}


Offloader::~Offloader()
{
}

} /* namespace autoblock */
