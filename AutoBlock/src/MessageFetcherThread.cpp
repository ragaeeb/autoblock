#include "precompiled.h"

#include "MessageFetcherThread.h"
#include "MessageImporter.h"
#include "Logger.h"

namespace autoblock {

using namespace canadainc;
using namespace bb::pim::message;

MessageFetcherThread::MessageFetcherThread(QByteArray const& data, QString const& uri, QObject* parent) :
		QObject(parent), m_data(data), m_uri(uri)
{
}


void MessageFetcherThread::run()
{
    QVariantMap result;

    qint64 accountId = 0;
    qint64 messageId = 0;

    if ( !m_data.isEmpty() )
    {
        bb::data::JsonDataAccess jda;
        QVariantMap json = jda.loadFromBuffer(m_data).toMap().value("attributes").toMap();

        if ( json.contains("accountid") && json.contains("messageid") )
        {
            accountId = json.value("accountid").toLongLong();
            messageId = json.value("messageid").toLongLong();
        }
    } else if ( !m_uri.isEmpty() ) {
        QStringList tokens = m_uri.split(":");

        if ( tokens.size() > 3 ) {
            accountId = tokens[2].toLongLong();
            messageId = tokens[3].toLongLong();
        } else {
            LOGGER("NotEnoughTokens" << tokens);
        }
    }

    LOGGER("Tokens" << accountId << messageId);

    if (accountId && messageId)
    {
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
