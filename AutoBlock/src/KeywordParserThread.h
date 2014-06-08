#ifndef KEYWORDPARSERTHREAD_H_
#define KEYWORDPARSERTHREAD_H_

#include <QObject>
#include <QRunnable>
#include <QVariant>

namespace autoblock {

class KeywordParserThread : public QObject, public QRunnable
{
	Q_OBJECT

	QVariantList m_messages;
	QVariantList m_excluded;

signals:
	void keywordsExtracted(QStringList const& keywords);

public:
	KeywordParserThread(QVariantList const& messages, QObject* parent=NULL);
	virtual ~KeywordParserThread();
    Q_SLOT void dataReady(int id, QVariant const& data);

	void run();
};

} /* namespace autoblock */
#endif /* KEYWORDPARSERTHREAD_H_ */
