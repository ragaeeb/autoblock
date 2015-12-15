#ifndef OFFLOADER_H_
#define OFFLOADER_H_

#include <bb/system/LocaleHandler>

#include <bb/utility/i18n/CustomDateFormatter>

namespace canadainc {
    class MessageImporter;
    class Persistance;
}

namespace autoblock {

using namespace bb::utility::i18n;
using namespace canadainc;

class Offloader : public QObject
{
    Q_OBJECT

    bb::system::LocaleHandler m_timeRender;
    MessageImporter* m_importer;
    Persistance* m_persist;
    CustomDateFormatter m_dateFormatter;

private slots:
    void onMessagesImported(QVariantList const& qvl);
    void terminateThreads();

signals:
    void accountsImported(QVariantList const& qvl);
    void loadProgress(int current, int total);
    void messagesImported(QVariantList const& qvl);

public:
    Offloader(Persistance* persist);
    virtual ~Offloader();

    Q_INVOKABLE QString renderStandardTime(QDateTime const& theTime);
    Q_INVOKABLE void loadAccounts();
    Q_INVOKABLE void loadMessages(qint64 accountId);

    void lazyInit();
};

} /* namespace autoblock */

#endif /* OFFLOADER_H_ */
