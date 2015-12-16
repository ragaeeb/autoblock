#ifndef BLOCKUTILS_H_
#define BLOCKUTILS_H_

#include <QMap>
#include <bb/pim/message/Message>

#define DATABASE_PATH QString("%1/database.db").arg( QDir::homePath() )
#define SERVICE_KEY "logService"
#define SERVICE_LOG_FILE QString("%1/logs/service.log").arg( QDir::currentPath() )
#define SETUP_FILE_PATH QString("%1/ready.log").arg( QDir::homePath() )
#define PUNCTUATION QRegExp("[\\.,!:;()]")

namespace bb {
    namespace pim {
        namespace message {
            class MessageService;
        }
    }
}

namespace autoblock {

using namespace bb::pim::message;

class BlockUtils
{
public:
	static QString isValidKeyword(QString const& keyword);
	static bool moveToTrash(qint64 accountId, qint64 messageId, MessageService* ms, QMap<qint64, quint64>& accountToTrash);
	static QList<Message> fetchRecentUnread(MessageService* ms, int max);
};

} /* namespace autoblock */

#endif /* BLOCKUTILS_H_ */
