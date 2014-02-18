#ifndef UPDATEMANAGER_H_
#define UPDATEMANAGER_H_

#include "NetworkProcessor.h"

namespace autoblock {

using namespace canadainc;

class UpdateManager : public QObject
{
    Q_OBJECT

    NetworkProcessor m_network;
    QHash<QString, bool> m_local;

private slots:
    void onRequestComplete(QVariant const& cookie, QByteArray const& data);

Q_SIGNALS:
    void updatesAvailable(QStringList const& addresses);

public:
    UpdateManager();
    virtual ~UpdateManager();

    void submit(QList<QVariantMap> const& all);
};

} /* namespace autoblock */

#endif /* UPDATEMANAGER_H_ */
