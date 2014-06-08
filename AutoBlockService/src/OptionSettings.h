#ifndef OPTIONSETTINGS_H_
#define OPTIONSETTINGS_H_

namespace autoblock {

struct OptionSettings
{
    bool blockStrangers;
    bool moveToTrash;
    bool sound;
    int threshold;
    bool whitelistContacts;
};

} /* namespace autoblock */

#endif /* OPTIONSETTINGS_H_ */
