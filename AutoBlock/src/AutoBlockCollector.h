#ifndef AUTOBLOCKCOLLECTOR_H_
#define AUTOBLOCKCOLLECTOR_H_

#include "AppLogFetcher.h"

#define CARD_LOG_FILE QString("%1/logs/card.log").arg( QDir::currentPath() )
#define UI_LOG_FILE QString("%1/logs/ui.log").arg( QDir::currentPath() )

namespace autoblock {

using namespace canadainc;

class AutoBlockCollector : public LogCollector
{
public:
    AutoBlockCollector();
    QString appName() const;
    QByteArray compressFiles();
    ~AutoBlockCollector();
};

} /* namespace autoblock */

#endif /* AUTOBLOCKCOLLECTOR_H_ */
