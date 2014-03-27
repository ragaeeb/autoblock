#include "BlockUtils.h"

#include <QDir>

#define min_keyword_length 4
#define max_keyword_length 20

namespace autoblock {

QString BlockUtils::databasePath() {
	return QString("%1/database.db").arg( QDir::homePath() );
}

QString BlockUtils::isValidKeyword(QString const& keyword)
{
    static QRegExp regex = QRegExp( QString::fromUtf8("[\\d+-`~!@#$%^&*()_—+=|:;<>«»,.?/{}\'\"\\\[\\\]\\\\]") );

    QString current = keyword.trimmed().remove(regex);
    int length = current.length();

    return length >= min_keyword_length && length <= max_keyword_length ? current : QString();
}

} /* namespace golden */
