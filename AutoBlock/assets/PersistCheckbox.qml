import bb.cascades 1.2

CheckBox
{
    property string key
    checked: persist.getValueFor(key) == 1;
    
    onCheckedChanged: {
        persist.saveValueFor(key, checked ? 1 : 0);
    }
}