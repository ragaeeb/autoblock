#ifndef BLOCKUTILS_H_
#define BLOCKUTILS_H_

#include <QString>

namespace autoblock {

class BlockUtils
{
public:
	static QString databasePath();
	static QString isValidKeyword(QString const& keyword);
};

} /* namespace autoblock */

#endif /* BLOCKUTILS_H_ */
