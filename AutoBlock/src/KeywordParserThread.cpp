#include "precompiled.h"

#include "BlockUtils.h"
#include "KeywordParserThread.h"
#include "Logger.h"

namespace {

void appendIfValid(QMap<QString,bool>& map, QStringList const& tokens)
{
    for (int i = tokens.size()-1; i >= 0; i--)
    {
        QString current = autoblock::BlockUtils::isValidKeyword( tokens[i] );

        if ( !current.isNull() ) {
            map[current] = true;
        }
    }
}

}

namespace autoblock {

KeywordParserThread::KeywordParserThread(QVariantList const& messages, QObject* parent) :
		QObject(parent), m_messages(messages)
{
}


void KeywordParserThread::run()
{
    QMap<QString,bool> map;
    QRegExp reg("\\s+");

    for (int i = m_messages.size()-1; i >= 0; i--)
    {
        QVariantMap current = m_messages[i].toMap();
        QString text = current.value("text").toString().trimmed();

        if ( !text.isEmpty() ) {
            appendIfValid( map, text.trimmed().toLower().split(reg, QString::SkipEmptyParts) );
        }

        text = current.value("subject").toString().trimmed();

        if ( !text.isEmpty() ) {
            appendIfValid( map, text.trimmed().toLower().split(reg, QString::SkipEmptyParts) );
        }
    }

    QStringList all = map.keys();
    qSort( all.begin(), all.end() );

    emit keywordsExtracted(all);
}


KeywordParserThread::~KeywordParserThread()
{
}

} /* namespace canadainc */
