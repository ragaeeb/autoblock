#ifndef QUERYHELPER_H_
#define QUERYHELPER_H_

#include <QDateTime>
#include <QObject>
#include <QStringList>

namespace canadainc {
	class CustomSqlDataSource;
}

namespace autoblock {

using namespace canadainc;

class QueryHelper : public QObject
{
	Q_OBJECT

	CustomSqlDataSource* m_sql;
    qint64 m_lastUpdate;

private slots:
    void dataLoaded(int id, QVariant const& data);

Q_SIGNALS:
    void dataReady(int id, QVariant const& data);

public:
	QueryHelper(CustomSqlDataSource* sql);
	virtual ~QueryHelper();

    Q_INVOKABLE void clearBlockedKeywords();
    Q_INVOKABLE void clearBlockedSenders();
    Q_INVOKABLE void clearLogs();
    Q_INVOKABLE void fetchAllBlockedKeywords();
    Q_INVOKABLE void fetchAllBlockedSenders();
    Q_INVOKABLE void fetchAllLogs();
    Q_INVOKABLE void fetchLatestLogs();
    Q_INVOKABLE QStringList block(QVariantList const& numbers);
    Q_INVOKABLE QStringList blockKeywords(QVariantList const& keywords);
    Q_INVOKABLE QStringList unblock(QVariantList const& senders);
    Q_INVOKABLE QStringList unblockKeywords(QVariantList const& keywords);
};

} /* namespace oct10 */
#endif /* QUERYHELPER_H_ */
