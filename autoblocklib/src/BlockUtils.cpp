#include "BlockUtils.h"

#include <QDir>

#include <bb/pim/message/MessageService>

#define min_keyword_length 3
#define max_keyword_length 20

namespace autoblock {

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


QString BlockUtils::isValidKeyword(QString const& keyword)
{
    QString current = keyword.trimmed();
    int length = current.length();

    return length >= min_keyword_length && length <= max_keyword_length ? current : QString();
}

} /* namespace golden */
