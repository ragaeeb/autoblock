#include "BlockUtils.h"

#include <QDir>

#include <bb/pim/account/AccountService>
#include <bb/pim/message/MessageFilter>
#include <bb/pim/message/MessageService>

#define min_keyword_length 3
#define max_keyword_length 20

namespace autoblock {

using namespace bb::pim::account;
using namespace bb::pim::message;

bool BlockUtils::moveToTrash(qint64 accountId, qint64 messageId, MessageService* ms, QMap<qint64, quint64>& accountToTrash)
{
    quint64 trashFolderId = 0;

    if ( !accountToTrash.contains(accountId) )
    {
        QList<MessageFolder> folders = ms->folders(accountId);

        for (int i = folders.size()-1; i >= 0; i--)
        {
            MessageFolder mf = folders[i];

            if ( mf.type() == MessageFolder::Trash ) {
                accountToTrash[accountId] = trashFolderId = mf.id();
            }
        }
    } else {
        trashFolderId = accountToTrash[accountId];
    }

    if (trashFolderId) {
        ms->file(accountId, messageId, trashFolderId);
    }

    return trashFolderId > 0;
}


QList<Message> BlockUtils::fetchRecentUnread(MessageService* ms, int maxVal)
{
    AccountService as;
    QList<Account> accounts = as.accounts(Service::Messages);
    QList<Message> result;

    qDebug() << "LDSKFJ" << maxVal;

    for (int i = accounts.size()-1; i >= 0; i--)
    {
        qint64 accountId = accounts[i].id();
        QList<Message> messages = ms->messages( accountId, MessageFilter() );

        bool readFound = false;
        int n = qMin( maxVal, messages.size() );

        qDebug() << "XX" << n << messages.size();

        for (int j = 0; (j < n) && !readFound; j++)
        {
            Message m = messages[j];

            if ( !m.isDraft() && m.isValid() && m.isInbound() )
            {
                if ( m.status().testFlag(MessageStatus::Read) ) {
                    readFound = true;
                } else {
                    result << m;
                }
            }
        }
    }

    qDebug() << "TOTAL" << result.size();

    return result;
}


QString BlockUtils::isValidKeyword(QString const& keyword)
{
    QString current = keyword.trimmed();
    int length = current.length();

    return length >= min_keyword_length && length <= max_keyword_length ? current : QString();
}

} /* namespace golden */
