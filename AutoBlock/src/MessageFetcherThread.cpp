#include "precompiled.h"

#include "MessageFetcherThread.h"
#include "MessageImporter.h"
#include "Logger.h"
#include "PimUtil.h"

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
    qint64 messageId = PimUtil::extractIdsFromInvoke(m_uri, m_data, accountId);

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
