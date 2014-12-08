#ifndef SERVICE_H_
#define SERVICE_H_

#include <QFileSystemWatcher>
#include <bb/system/InvokeManager>
#include <bb/system/phone/Phone>
#include <bb/pim/message/MessageService>

#include "customsqldatasource.h"
#include "OptionSettings.h"
#include "QueryId.h"

namespace bb {
	class Application;

	namespace multimedia {
	    class SystemSound;
	}
}

namespace autoblock {

using namespace bb::pim::message;
using namespace bb::system;
using namespace bb::system::phone;
using namespace canadainc;

struct PendingQueue
{
    QQueue<Message> senderQueue;
    QQueue<Message> keywordQueue;
    QQueue<Call> callQueue;
    QMap<QString, bool> phoneToPending;
    int lastCallId;
};

class Service: public QObject
{
	Q_OBJECT

	OptionSettings m_options;
    MessageService m_manager;
    Phone m_phone;
	QFileSystemWatcher m_settingsWatcher;
	InvokeManager m_invokeManager;
	CustomSqlDataSource m_sql;
	PendingQueue m_queue;
	QMap<qint64, quint64> m_accountToTrash;

    void forceDelete(Message const& m);
	void processSenders(QVariantList result);
	void processKeywords(QVariantList result);
	void processCalls(QVariantList result);
	void process(Message const& m);
	void spamDetected(Message const& m);
	void setup(bool replace=true);
	void updateCount(QVariantList result, QString const& field, QString const& table, QueryId::Type t);
    void updateLog(QString const& address, QString const& message);

private slots:
    void callUpdated(bb::system::phone::Call const& call);
    void dataLoaded(int id, QVariant const& data);
	void handleInvoke(const bb::system::InvokeRequest &);
	void init();
	void messageAdded(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey);
	void settingChanged(QString const& key=QString());

Q_SIGNALS:
	void initialize();

public:
	Service(bb::Application* app);
};

}

#endif /* SERVICE_H_ */
