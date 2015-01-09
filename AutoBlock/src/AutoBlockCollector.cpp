#include "AutoBlockCollector.h"
#include "BlockUtils.h"
#include "JlCompress.h"

namespace autoblock {

using namespace canadainc;

AutoBlockCollector::AutoBlockCollector()
{
}


QByteArray AutoBlockCollector::compressFiles()
{
    AppLogFetcher::dumpDeviceInfo();

    QStringList files;
    files << DEFAULT_LOGS;
    files << CARD_LOG_FILE;
    files << DATABASE_PATH;
    files << SERVICE_LOG_FILE;

    for (int i = files.size()-1; i >= 0; i--)
    {
        if ( !QFile::exists(files[i]) ) {
            files.removeAt(i);
        }
    }

    JlCompress::compressFiles(ZIP_FILE_PATH, files);

    QFile f(ZIP_FILE_PATH);
    f.open(QIODevice::ReadOnly);

    QByteArray qba = f.readAll();
    f.close();

    QFile::remove(CARD_LOG_FILE);
    QFile::remove(SERVICE_LOG_FILE);
    QFile::remove(UI_LOG_FILE);

    return qba;
}


AutoBlockCollector::~AutoBlockCollector()
{
}

} /* namespace autoblock */
