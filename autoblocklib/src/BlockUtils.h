#ifndef BLOCKUTILS_H_
#define BLOCKUTILS_H_

#include <QMap>

#define SERVICE_KEY "logService"
#define SERVICE_LOG_FILE QString("%1/logs/service.log").arg( QDir::currentPath() )
#define PUNCTUATION QRegExp("[\\.,!:;()]")

namespace bb {
    namespace pim {
        namespace message {
            class Message;
            class MessageService;
        }
    }
}

namespace autoblock {

using namespace bb::pim::message;

class BlockUtils
{
public:
	static QString databasePath();
	static QString isValidKeyword(QString const& keyword);
	static bool moveToTrash(qint64 accountId, qint64 messageId, MessageService* ms, QMap<qint64, quint64>& accountToTrash);
	static QString setupFilePath();
};

} /* namespace autoblock */

#endif /* BLOCKUTILS_H_ */
