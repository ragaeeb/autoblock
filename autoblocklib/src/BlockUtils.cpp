#include "BlockUtils.h"

#include <QDir>

namespace autoblock {

QString BlockUtils::databasePath() {
	return QString("%1/database.db").arg( QDir::homePath() );
}

QString BlockUtils::isValidKeyword(QString const& keyword)
{
    QString current = keyword.trimmed();
    int length = current.length();

    return length >= min_keyword_length && length <= max_keyword_length ? current : QString();
}

} /* namespace golden */
