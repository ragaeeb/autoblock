#ifndef AutoBlock_HPP_
#define AutoBlock_HPP_

#include <QFileSystemWatcher>

#include <bb/system/CardDoneMessage>
#include <bb/system/InvokeManager>

#include "customsqldatasource.h"
#include "LazySceneCover.h"
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
    Q_PROPERTY(bool accountSelected READ accountSelected NOTIFY accountSelectedChanged)

    LazySceneCover m_cover;
    CustomSqlDataSource m_sql;
    Persistance m_persistance;
    QueryHelper m_helper;
    bb::system::InvokeManager m_invokeManager;
    QFileSystemWatcher m_updateWatcher;
    MessageImporter* m_importer;
    UpdateManager m_update;

    AutoBlock(Application *app);
    void recheck(int &count, const char* slotName);
    QObject* initRoot(QString const& qml="main.qml", bool invoked=false);
    void parseKeywords(QVariantList const& toProcess);
    void finishWithToast(QString const& message);
    void portClassic();

private slots:
    void checkDatabase();
    void childCardDone(bb::system::CardDoneMessage const& message=bb::system::CardDoneMessage());
	void databaseUpdated(QString const& path);
	void init();
	void invoked(bb::system::InvokeRequest const& request);
    void messageFetched(QVariantMap const& result);
    void onKeywordsExtracted(QStringList const& keywords);
    void onMessagesImported(QVariantList const& qvl);
    void onKeywordsSelected(QVariant k);
	void settingChanged(QString const& key);

Q_SIGNALS:
	void initialize();
	void accountSelectedChanged();
	void accountsImported(QVariantList const& qvl);
	void messagesImported(QVariantList const& qvl);
	void loadProgress(int current, int total);
	void keywordsExtracted(QStringList const& keywords);
	void updatesAvailable(QStringList const& addresses);

public:
	static void create(Application *app);
    virtual ~AutoBlock();
    bool accountSelected();

    Q_INVOKABLE void loadAccounts();
    Q_INVOKABLE void loadMessages(qint64 accountId);
    Q_INVOKABLE void extractKeywords(QVariantList const& messages);
    Q_INVOKABLE QString validateKeyword(QString const& keyword);
    Q_INVOKABLE void submit(QObject* gdm);
};

}

#endif /* AutoBlock_HPP_ */
