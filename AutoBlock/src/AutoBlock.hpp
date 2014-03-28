#ifndef AutoBlock_HPP_
#define AutoBlock_HPP_

#include <QFileSystemWatcher>

#include <bb/system/CardDoneMessage>
#include <bb/system/InvokeManager>

#include "AppLogFetcher.h"
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
    AppLogFetcher m_reporter;

    AutoBlock(Application *app);
    void finishWithToast(QString const& message);
    QObject* initRoot(QString const& qml="main.qml", bool invoked=false);
    void parseKeywords(QVariantList const& toProcess);
    void portClassic();
    void recheck(int &count, const char* slotName);

private slots:
    void checkDatabase();
    void childCardDone(bb::system::CardDoneMessage const& message=bb::system::CardDoneMessage());
	void databaseUpdated(QString const& path);
	void init();
	void invoked(bb::system::InvokeRequest const& request);
    void messageFetched(QVariantMap const& result);
    void onKeywordsExtracted(QStringList const& keywords);
    void onKeywordsSelected(QVariant k);
    void onMessagesImported(QVariantList const& qvl);
	void settingChanged(QString const& key);
	void terminateThreads();

Q_SIGNALS:
    void accountsImported(QVariantList const& qvl);;
	void accountSelectedChanged();
    void initialize();
    void keywordsExtracted(QStringList const& keywords);
	void loadProgress(int current, int total);
    void messagesImported(QVariantList const& qvl);

public:
	static void create(Application *app);
    virtual ~AutoBlock();
    bool accountSelected();
    Q_INVOKABLE void extractKeywords(QVariantList const& messages);
    Q_INVOKABLE void loadAccounts();
    Q_INVOKABLE void loadMessages(qint64 accountId);
    Q_INVOKABLE void submit(QObject* gdm);
    Q_INVOKABLE QString validateKeyword(QString const& keyword);
};

}

#endif /* AutoBlock_HPP_ */
