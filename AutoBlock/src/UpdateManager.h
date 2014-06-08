#ifndef UPDATEMANAGER_H_
#define UPDATEMANAGER_H_

#include "NetworkProcessor.h"

namespace autoblock {

using namespace canadainc;

class UpdateManager : public QObject
{
    Q_OBJECT

    NetworkProcessor m_network;

private slots:
    void onCompressed();
    void onUncompressed();
    void onRequestComplete(QVariant const& cookie, QByteArray const& data);

Q_SIGNALS:
    void downloadProgress(QVariant const&, qint64 bytesReceived, qint64 bytesTotal);
    void updatesAvailable(QVariantList const& addresses);

public:
    UpdateManager();
    virtual ~UpdateManager();

    Q_SLOT void submit();
};

} /* namespace autoblock */

#endif /* UPDATEMANAGER_H_ */
