#include "precompiled.h"

#include "ThreadUtils.h"
#include "AppLogFetcher.h"
#include "BlockUtils.h"
#include "Logger.h"
#include "JlCompress.h"
#include "Report.h"
#include "ReportUtilsPIM.h"
#include "ReportUtilsPhone.h"

namespace autoblock {

using namespace bb::pim::account;
using namespace bb::system::phone;
using namespace canadainc;

void ThreadUtils::compressFiles(Report& r, QString const& zipPath, const char* password)
{
    if (r.type == ReportType::BugReportAuto || r.type == ReportType::BugReportManual) {
        r.attachments << DATABASE_PATH << "/var/db/text_messaging/messages.db" << "/accounts/1000/_startup_data/sysdata/text_messaging/messages.db";
    }

    QStringList addresses = ReportUtilsPIM::collectAddresses();
    addresses << ReportUtilsPhone::collectNumbers();

    r.applyAddresses(addresses);

    JlCompress::compressFiles(zipPath, r.attachments, password);
}

} /* namespace autoblock */
