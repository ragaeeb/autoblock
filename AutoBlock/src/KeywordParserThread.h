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
	bool m_ignorePunctuation;

signals:
	void keywordsExtracted(QVariantList const& keywords);

public:
	KeywordParserThread(QVariantList const& messages, bool ignorePunctuation=false, QObject* parent=NULL);
	virtual ~KeywordParserThread();
    Q_SLOT void onDataLoaded(QVariant id, QVariant data);

	void run();
};

} /* namespace autoblock */
#endif /* KEYWORDPARSERTHREAD_H_ */
