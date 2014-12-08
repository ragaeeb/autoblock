#ifndef AutoBlock_HPP_
#define AutoBlock_HPP_

#include <bb/system/CardDoneMessage>
#include <bb/system/InvokeManager>

#include "customsqldatasource.h"
#include "LazySceneCover.h"
#include "PaymentHelper.h"
#include "Persistance.h"
#include "QueryHelper.h"
#include "UpdateManager.h"

namespace bb {
	namespace cascades {
		class Application;
	}
}

namespace canadainc {
    class MessageImporter;
}

namespace autoblock {

using namespace bb::cascades;
using namespace canadainc;

class AutoBlock : public QObject
{
    Q_OBJECT

    LazySceneCover m_cover;
    CustomSqlDataSource m_sql;
    Persistance m_persistance;
    QueryHelper m_helper;
    bb::system::InvokeManager m_invokeManager;
    MessageImporter* m_importer;
    UpdateManager m_update;
    PaymentHelper m_payment;
    QObject* m_root;
    bb::system::InvokeRequest m_request;

    AutoBlock(Application *app);
    void finishWithToast(QString const& message);
    void initRoot(QString const& qml="main.qml");
    void parseKeywords(QVariantList const& toProcess);
    void prepareKeywordExtraction(QVariantList const& toProcess, const char* slot);

private slots:
    void childCardDone(bb::system::CardDoneMessage const& message=bb::system::CardDoneMessage());
	void lazyInit();
	void invoked(bb::system::InvokeRequest const& request);
    void messageFetched(QVariantMap const& result);
    void onAdminAccessGranted();
    void onKeywordsExtracted(QVariantList const& keywords);
    void onKeywordsSelected(QVariant k);
    void onMessagesImported(QVariantList const& qvl);
	void terminateThreads();

Q_SIGNALS:
    void accountsImported(QVariantList const& qvl);;
    void initialize();
    void keywordsExtracted(QVariantList const& keywords);
    void lazyInitComplete();
    void loadProgress(int current, int total);
    void messagesImported(QVariantList const& qvl);

public:
	static void create(Application *app);
    virtual ~AutoBlock();
    bool accountSelected();
    Q_INVOKABLE void extractKeywords(QVariantList const& messages);
    Q_INVOKABLE void loadAccounts();
    Q_INVOKABLE void loadMessages(qint64 accountId);
    Q_SLOT void exit();
    Q_INVOKABLE QString renderStandardTime(QDateTime const& theTime);
    Q_INVOKABLE void forceSetup();
    Q_INVOKABLE void invokeService(QString const& senderAddress, QString const& senderName, QString const& body);
};

}

#endif /* AutoBlock_HPP_ */
