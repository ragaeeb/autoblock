#include "precompiled.h"

#include "MessageFetcherThread.h"
#include "MessageImporter.h"
#include "Logger.h"

namespace autoblock {

using namespace canadainc;
using namespace bb::pim::message;

MessageFetcherThread::MessageFetcherThread(QByteArray const& data, QObject* parent) :
		QObject(parent), m_data(data)
{
}


void MessageFetcherThread::run()
{
    bb::data::JsonDataAccess jda;
    QVariantMap json = jda.loadFromBuffer(m_data).toMap().value("attributes").toMap();

    QVariantMap result;

    if ( json.contains("accountid") && json.contains("messageid") )
    {
        qint64 accountId = json.value("accountid").toLongLong();
        qint64 messageId = json.value("messageid").toLongLong();

        LOGGER("Tokens" << accountId << messageId);

        MessageService m;
        Message message = m.message(accountId, messageId);

        result = MessageImporter::transform(message);
        result["accountId"] = accountId;
    }

    LOGGER("Result" << result);
    emit messageFetched(result);
}


MessageFetcherThread::~MessageFetcherThread()
{
}

} /* namespace canadainc */
