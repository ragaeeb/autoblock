#ifndef SERVICE_H_
#define SERVICE_H_

#include <QFileSystemWatcher>
#include <QQueue>

#include <bb/system/InvokeManager>

#include <bb/pim/message/MessageService>

#include "customsqldatasource.h"

namespace bb {
	class Application;

	namespace multimedia {
	    class SystemSound;
	}
}

namespace autoblock {

using namespace bb::pim::message;
using namespace bb::system;
using namespace canadainc;

class Service: public QObject
{
	Q_OBJECT

    QQueue<qint64> m_pending;
	bool m_sound;
	int m_threshold;
    MessageService m_manager;
	QFileSystemWatcher m_settingsWatcher;
	InvokeManager m_invokeManager;
	CustomSqlDataSource m_sql;
	QQueue<Message> m_senderQueue;
	QQueue<Message> m_keywordQueue;

	void processSenders(QVariantList result);
	void processKeywords(QVariantList result);
	void spamDetected(Message const& m);

private slots:
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
