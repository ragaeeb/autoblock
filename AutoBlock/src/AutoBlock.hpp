#ifndef AutoBlock_HPP_
#define AutoBlock_HPP_

#include <bb/system/CardDoneMessage>
#include <bb/system/InvokeManager>

#include "DeviceUtils.h"
#include "LazySceneCover.h"
#include "Offloader.h"
#include "PaymentHelper.h"
#include "Persistance.h"
#include "QueryHelper.h"
#include "UpdateManager.h"

namespace bb {
	namespace cascades {
		class Application;
	}
}

namespace autoblock {

using namespace bb::cascades;
using namespace bb::system;
using namespace canadainc;

class AutoBlock : public QObject
{
    Q_OBJECT

    LazySceneCover m_cover;
    Persistance m_persistance;
    QueryHelper m_helper;
    bb::system::InvokeManager m_invokeManager;
    UpdateManager m_update;
    PaymentHelper m_payment;
    QObject* m_root;
    bb::system::InvokeRequest m_request;
    Offloader m_offloader;
    DeviceUtils m_device;

    void finishWithToast(QString const& message);
    void initRoot(QString const& qml="main.qml");
    void parseKeywords(QVariantList const& toProcess);
    void prepareKeywordExtraction(QVariantList const& toProcess, const char* slot);

private slots:
    void completeInvoke();
    void childCardDone(bb::system::CardDoneMessage const& message=bb::system::CardDoneMessage());
	void lazyInit();
	void invoked(bb::system::InvokeRequest const& request);
    void messageFetched(QVariantMap const& result);
    void onKeywordsExtracted(QVariantList const& keywords);
    void onKeywordsSelected(QVariant k);

Q_SIGNALS:
    void initialize();
    void keywordsExtracted(QVariantList const& keywords);
    void lazyInitComplete();

public:
    AutoBlock(InvokeManager* i);
    virtual ~AutoBlock();
    bool accountSelected();
    Q_INVOKABLE void extractKeywords(QVariantList const& messages);
    Q_SLOT void exitAfterRestore();
    Q_INVOKABLE void forceSetup();
    Q_INVOKABLE void invokeService(QString const& senderAddress, QString const& senderName, QString const& body);
    Q_INVOKABLE QString bytesToSize(qint64 size);
};

}

#endif /* AutoBlock_HPP_ */
