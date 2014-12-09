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
        AttachReportedDatabase,
        BlockKeywords,
        BlockSenderChunk,
    	BlockSenders,
    	ClearLogs,
    	FetchBlockedKeywords,
    	FetchBlockedSenders,
        FetchAllLogs,
        FetchAllReported,
        FetchExcludedWords,
        FetchLatestLogs,
    	LogTransaction,
        LookupCaller,
        LookupKeyword,
    	LookupSender,
    	Optimize,
        SettingUp,
        Setup,
    	UnblockKeywords,
    	UnblockSenders
    };
};

}

#endif /* QUERYID_H_ */
