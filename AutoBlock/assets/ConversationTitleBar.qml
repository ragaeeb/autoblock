import bb.cascades 1.0

TitleBar
{
    id: titleControl
    property alias accounts: accountChoice
    kind: TitleBarKind.FreeForm
    scrollBehavior: TitleBarScrollBehavior.NonSticky
    kindProperties: FreeFormTitleBarKindProperties
    {
        Container
        {
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            topPadding: 10; bottomPadding: 20; leftPadding: 10
            
            Label {
                id: daysLabel
                verticalAlignment: VerticalAlignment.Center
                textStyle.base: SystemDefaults.TextStyles.BigText
                textStyle.color: 'Signature' in ActionBarPlacement ? Color.Black : Color.White
            }
        }
        
        expandableArea
        {
            expanded: true
            
            content: Container
            {
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Fill
                leftPadding: 10; rightPadding: 10; topPadding: 5
                
                AccountsDropDown
                {
                    id: accountChoice
                    controller: offloader
                    selectedAccountId: persist.getValueFor("accountId")
                    
                    onAccountsLoaded: {
                        if (numAccounts == 0) {
                            toaster.init( qsTr("Did not find any accounts. Maybe the app does not have the permissions it needs..."), "images/ic_account.png" );
                        } else if (selectedOption == null) {
                            expanded = true;
                        }
                    }
                    
                    onSelectedOptionChanged: {
                        var value = selectedOption.value;
                        var changed = persist.saveValueFor("accountId", value, false);
                        
                        if (changed) {
                            console.log("UserEvent: AccountDropDownChanged", value);
                        }
                        
                        offloader.loadMessages(value, selectedOption.isCellular);
                        reporter.record("AccountSelected", value);
                    }
                }
                
                Slider {
                    value: persist.getValueFor("days")
                    horizontalAlignment: HorizontalAlignment.Fill
                    fromValue: 1
                    toValue: 30
                    
                    onValueChanged: {
                        var actualValue = Math.floor(value);
                        var changed = persist.saveValueFor("days", actualValue, false);
                        daysLabel.text = qsTr("Days to Fetch: %1").arg(actualValue);
                        
                        if (accountChoice.selectedOption != null && changed)
                        {
                            accountChoice.selectedOptionChanged(accountChoice.selectedOption);
                            reporter.record("DaysToFetch", value);
                        }
                    }
                }
            }
        }
    }
}