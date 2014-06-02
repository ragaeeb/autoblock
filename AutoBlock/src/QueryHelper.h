#ifndef QUERYHELPER_H_
#define QUERYHELPER_H_

#include <QStringList>
#include <QFileSystemWatcher>

#include "QueryId.h"

namespace canadainc {
    class AppLogFetcher;
	class CustomSqlDataSource;
}

namespace bb {
    namespace pim {
        namespace message {
            class MessageService;
        }
    }
}

namespace autoblock {

using namespace canadainc;
using namespace bb::pim::message;

class QueryHelper : public QObject
{
	Q_OBJECT

	AppLogFetcher* m_reporter;
	CustomSqlDataSource* m_sql;
    MessageService* m_ms;
    qint64 m_lastUpdate;
    QFileSystemWatcher m_updateWatcher;
    bool m_logSearchMode;

    void recheck(int &count, const char* slotName);
    void prepareTransaction(QString const& query, QVariantList const& elements, QueryId::Type qid);

private slots:
    void databaseUpdated(QString const& path);
    void dataLoaded(int id, QVariant const& data);
    void onError(QString const& errorMessage);

Q_SIGNALS:
    void dataReady(int id, QVariant const& data);

public:
	QueryHelper(CustomSqlDataSource* sql, AppLogFetcher* reporter);
	virtual ~QueryHelper();

    Q_INVOKABLE void clearBlockedKeywords();
    Q_INVOKABLE void clearBlockedSenders();
    Q_INVOKABLE void cleanInvalidEntries();
    Q_INVOKABLE void clearLogs();
    Q_INVOKABLE void fetchAllBlockedKeywords(QString const& filter=QString());
    Q_INVOKABLE void fetchAllBlockedSenders(QString const& filter=QString());
    Q_INVOKABLE void fetchAllLogs(QString const& filter=QString());
    Q_INVOKABLE void fetchLatestLogs();
    Q_INVOKABLE QStringList block(QVariantList const& numbers);
    Q_INVOKABLE QStringList blockKeywords(QVariantList const& keywords);
    Q_INVOKABLE QStringList unblock(QVariantList const& senders);
    Q_INVOKABLE QStringList unblockKeywords(QVariantList const& keywords);
    Q_SLOT void checkDatabase();
};

} /* namespace oct10 */
#endif /* QUERYHELPER_H_ */
