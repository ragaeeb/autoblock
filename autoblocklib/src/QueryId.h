#ifndef QUERYID_H_
#define QUERYID_H_

#include <qobjectdefs.h>

namespace autoblock {

class QueryId
{
    Q_GADGET
    Q_ENUMS(Type)

public:
    enum Type {
        BlockKeywords,
    	BlockSenders,
    	ClearLogs,
    	FetchBlockedKeywords,
    	FetchBlockedSenders,
        FetchAllLogs,
        FetchExcludedWords,
        FetchLatestLogs,
    	LogTransaction,
        LookupKeyword,
    	LookupSender,
    	Optimize,
    	UnblockKeywords,
    	UnblockSenders,
    	Setup
    };
};

}

#endif /* QUERYID_H_ */
