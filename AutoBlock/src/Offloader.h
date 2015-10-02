#ifndef OFFLOADER_H_
#define OFFLOADER_H_

#include <bb/system/LocaleHandler>

namespace bb {
    namespace cascades {
        namespace maps {
            class MapView;
        }
    }
}

namespace autoblock {

class Offloader : public QObject
{
    Q_OBJECT

    bb::system::LocaleHandler m_timeRender;

signals:
    void accountsImported(QVariantList const& qvl);
    void operationProgress(int current, int total);
    void operationComplete(QString const& toastMessage, QString const& icon);

public:
    Offloader();
    virtual ~Offloader();

    Q_INVOKABLE QString renderStandardTime(QDateTime const& theTime);
    Q_INVOKABLE void loadAccounts();
};

} /* namespace autoblock */

#endif /* OFFLOADER_H_ */
