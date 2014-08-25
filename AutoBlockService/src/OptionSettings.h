#ifndef OPTIONSETTINGS_H_
#define OPTIONSETTINGS_H_

namespace autoblock {

struct OptionSettings
{
    bool blockStrangers;
    bool ignorePunctuation;
    bool moveToTrash;
    bool scanAddress;
    bool scanName;
    bool sound;
    int threshold;
    bool whitelistContacts;

    OptionSettings() : blockStrangers(false), ignorePunctuation(false), moveToTrash(false),
            scanAddress(false), scanName(false), sound(false), threshold(3), whitelistContacts(false)
    {
    }
};

} /* namespace autoblock */

#endif /* OPTIONSETTINGS_H_ */
