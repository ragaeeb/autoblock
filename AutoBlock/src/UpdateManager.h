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
    void onSaved();
    void onRestored();
    void onCompressed();
    void onUncompressed();
    void onRequestComplete(QVariant const& cookie, QByteArray const& data);

Q_SIGNALS:
    void backupComplete(QString const& file);
    void restoreComplete(bool success);
    void downloadProgress(QVariant const&, qint64 bytesReceived, qint64 bytesTotal);
    void updatesAvailable(QVariantList const& addresses);

public:
    UpdateManager();
    virtual ~UpdateManager();

    Q_SLOT void submit();
    Q_INVOKABLE void backup(QString const& destination);
    Q_INVOKABLE void restore(QString const& source);
};

} /* namespace autoblock */

#endif /* UPDATEMANAGER_H_ */
