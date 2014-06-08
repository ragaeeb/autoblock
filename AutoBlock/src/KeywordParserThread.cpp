#include "precompiled.h"

#include "BlockUtils.h"
#include "KeywordParserThread.h"
#include "Logger.h"
#include "IOUtils.h"
#include "QueryId.h"

namespace {

bool running = false;

void appendIfValid(QMap<QString,bool>& map, QStringList const& tokens, QMap<QString, bool> const& excluded)
{
    for (int i = tokens.size()-1; i >= 0; i--)
    {
        QString current = autoblock::BlockUtils::isValidKeyword( tokens[i] );

        if ( !current.isNull() && !excluded.contains(current) ) {
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

    QMap<QString, bool> excluded;

    for (int i = m_excluded.size()-1; i >= 0; i--)
    {
        QString excludedWord = m_excluded[i].toMap().value("word").toString();
        excluded[excludedWord] = true;
    }

    for (int i = m_messages.size()-1; i >= 0; i--)
    {
        QVariantMap current = m_messages[i].toMap();
        QString text = current.value("text").toString().trimmed();

        if ( !text.isEmpty() ) {
            appendIfValid( map, text.trimmed().toLower().split(reg, QString::SkipEmptyParts), excluded );
        }

        text = current.value("subject").toString().trimmed();

        if ( !text.isEmpty() ) {
            appendIfValid( map, text.trimmed().toLower().split(reg, QString::SkipEmptyParts), excluded );
        }
    }

    QStringList all = map.keys();
    qSort( all.begin(), all.end() );

    emit keywordsExtracted(all);
    running = false;
}


void KeywordParserThread::dataReady(int id, QVariant const& data)
{
    if (id == QueryId::FetchExcludedWords) {
        m_excluded = data.toList();
    }

    if (!running) {
        canadainc::IOUtils::startThread(this);
        running = true;
    }
}


KeywordParserThread::~KeywordParserThread()
{
}

} /* namespace canadainc */
