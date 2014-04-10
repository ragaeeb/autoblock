#include "precompiled.h"

#include "MessageFetcherThread.h"
#include "MessageImporter.h"
#include "Logger.h"

namespace autoblock {

using namespace canadainc;
using namespace bb::pim::message;

MessageFetcherThread::MessageFetcherThread(QStringList const& tokens, QObject* parent) :
		QObject(parent), m_tokens(tokens)
{
}


void MessageFetcherThread::run()
{
    qint64 accountId = m_tokens[2].toLongLong();
    qint64 messageId = m_tokens[3].toLongLong();

    LOGGER("Tokens" << m_tokens);
    LOGGER("Message Tokens" << accountId << messageId);

    MessageService m;
    Message message = m.message(accountId, messageId);

    QVariantMap result = MessageImporter::transform(message);
    result["accountId"] = accountId;

    LOGGER("Result" << result);

    emit messageFetched(result);
}


MessageFetcherThread::~MessageFetcherThread()
{
}

} /* namespace canadainc */
