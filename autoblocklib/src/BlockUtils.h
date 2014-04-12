#ifndef BLOCKUTILS_H_
#define BLOCKUTILS_H_

#include <QString>

#define SERVICE_KEY "logService"
#define SERVICE_LOG_FILE QString("%1/logs/service.log").arg( QDir::currentPath() )

namespace autoblock {

class BlockUtils
{
public:
	static QString databasePath();
	static QString isValidKeyword(QString const& keyword);
};

} /* namespace autoblock */

#endif /* BLOCKUTILS_H_ */
