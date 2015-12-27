#include "precompiled.h"

#include "ThreadUtils.h"
#include "AppLogFetcher.h"
#include "Logger.h"
#include "JlCompress.h"
#include "Report.h"
#include "BlockUtils.h"

namespace autoblock {

using namespace bb::pim::account;
using namespace bb::system::phone;
using namespace canadainc;

void ThreadUtils::compressFiles(Report& r, QString const& zipPath, const char* password)
{
    if (r.type == ReportType::BugReportAuto || r.type == ReportType::BugReportManual) {
        r.attachments << DATABASE_PATH;
    }

    AccountService as;
    QList<Account> accounts = as.accounts(Service::Messages);
    QStringList addresses;

    for (int i = accounts.size()-1; i >= 0; i--)
    {
        Account a = accounts[i];
        QString provider = a.provider().id();
        QVariantMap settings = a.rawData()["settings"].toMap();
        QString address = settings["email_address"].toMap()["value"].toString().trimmed();

        if ( !address.isEmpty() ) {
            addresses << address.trimmed();
        }
    }

    QMap<QString, Line> lines = Phone().lines();

    if ( !lines["cellular"].address().trimmed().isEmpty() ) {
        addresses << lines["cellular"].address().trimmed();
    }

    QString result;
    bb::data::JsonDataAccess j;
    j.saveToBuffer(QVariant::fromValue(addresses), &result);
    r.params.insert("addresses", result);

    JlCompress::compressFiles(zipPath, r.attachments, password);
}

} /* namespace autoblock */
