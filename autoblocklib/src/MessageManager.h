#ifndef MESSAGEMANAGER_H_
#define MESSAGEMANAGER_H_

#include <QObject>
#include <QList>

#include <bb/pim/account/Account>
#include <bb/pim/message/Conversation>
#include <bb/pim/message/Message>

namespace bb {
	namespace pim {
		namespace message {
			class MessageService;
		}
	}
}

namespace canadainc {

using namespace bb::pim::message;

class MessageManager : public QObject
{
	Q_OBJECT

	Q_PROPERTY(bool monitoring READ monitoring WRITE setMonitoring NOTIFY monitoringStateChanged)

	MessageService* m_ms;
    qint64 m_accountKey;
    bool m_connected;

    void initService();

private slots:
    void messageAdded(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey);
    void messageUpdated(bb::pim::account::AccountKey accountId, bb::pim::message::ConversationKey conversationId, bb::pim::message::MessageKey messageId, bb::pim::message::MessageUpdate data);

Q_SIGNALS:
	void monitoringStateChanged();
	void messageReceived(Message const& m, qint64 accountKey, QString const& conversationKey);
	void messageSent(Message const& m, qint64 accountKey, QString const& conversationKey);

public:
	MessageManager(qint64 accountKey=0, QObject* parent=NULL);
	virtual ~MessageManager();

	Q_SLOT bool setMonitoring(bool monitor);
	bool monitoring() const;
	Message getMessage(qint64 mk);
	qint64 sendMessage(Message const& m, QString text, QList<Attachment> const& attachments=QList<Attachment>(), bool replyPrefix=false);
	void remove(QString const& ck, qint64 mk);
	void setAccountKey(qint64 accountKey);

	static const int account_key_sms;
};

} /* namespace canadainc */
#endif /* SMSMANAGER_H_ */
