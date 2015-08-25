# Change Logs #
v3.7.0.0:
  * [Issue 180](https://code.google.com/p/autoblock/issues/detail?id=180) Database access attempted before setup is complete
  * [Issue 181](https://code.google.com/p/autoblock/issues/detail?id=181) Insertion failure
  * [Issue 182](https://code.google.com/p/autoblock/issues/detail?id=182) Element picker page complains about reporter when launched from a card
  * [Issue 183](https://code.google.com/p/autoblock/issues/detail?id=183) Release memory when card is pooled
  * [Issue 184](https://code.google.com/p/autoblock/issues/detail?id=184) Allow suppressing tutorials
  * [Issue 185](https://code.google.com/p/autoblock/issues/detail?id=185) Toasts that block the UI thread can put app in a bad state
  * [Issue 186](https://code.google.com/p/autoblock/issues/detail?id=186) Grey text on white background in older 10.2.1 OS builds

v3.6.0.0:
  * [Issue 142](https://code.google.com/p/autoblock/issues/detail?id=142) Blocking spammers from hub not working.
  * [Issue 144](https://code.google.com/p/autoblock/issues/detail?id=144) Under conversations, unable to select anything except WORK account
  * [Issue 145](https://code.google.com/p/autoblock/issues/detail?id=145) stuck on permissions not fully given message
  * [Issue 146](https://code.google.com/p/autoblock/issues/detail?id=146) Error during self-exclude logic
  * [Issue 152](https://code.google.com/p/autoblock/issues/detail?id=152) Log user events
  * [Issue 153](https://code.google.com/p/autoblock/issues/detail?id=153) Use custom tutorial toasts
  * [Issue 154](https://code.google.com/p/autoblock/issues/detail?id=154) Show permission toasts in a custom control
  * [Issue 155](https://code.google.com/p/autoblock/issues/detail?id=155) Warn user if they disable the Phone permissions
  * [Issue 156](https://code.google.com/p/autoblock/issues/detail?id=156) Add divider between checkboxes and label in Settings page
  * [Issue 157](https://code.google.com/p/autoblock/issues/detail?id=157) Disable Search and Delete actions if lists are empty
  * [Issue 158](https://code.google.com/p/autoblock/issues/detail?id=158) Changing Days to Fetch slider doesn't seem to reload the list elements
  * [Issue 160](https://code.google.com/p/autoblock/issues/detail?id=160) Malformed database queries attempt to be ran after restore
  * [Issue 161](https://code.google.com/p/autoblock/issues/detail?id=161) Implement test harness
  * [Issue 162](https://code.google.com/p/autoblock/issues/detail?id=162) Inserting a large amount of keywords can fail insertion
  * [Issue 164](https://code.google.com/p/autoblock/issues/detail?id=164) Improve spam address server sync flow
  * [Issue 165](https://code.google.com/p/autoblock/issues/detail?id=165) Suggest to user to clear long logs to decrease startup time
  * [Issue 167](https://code.google.com/p/autoblock/issues/detail?id=167) Change all system toasts to custom toasts
  * [Issue 170](https://code.google.com/p/autoblock/issues/detail?id=170) Place Optimize action on the bottom bar in Settings page
  * [Issue 171](https://code.google.com/p/autoblock/issues/detail?id=171) Add support for Classic
  * [Issue 172](https://code.google.com/p/autoblock/issues/detail?id=172) If user has no elements in the blocked list Sync does not work
  * [Issue 175](https://code.google.com/p/autoblock/issues/detail?id=175) Conversations and keywords tab title bar text is black in 10.2.1
  * [Issue 176](https://code.google.com/p/autoblock/issues/detail?id=176) Possible to input empty entries into the keywords table
  * [Issue 177](https://code.google.com/p/autoblock/issues/detail?id=177) Scene cover is trying to do database lookups before app set is set up

v3.4.0.0:
  * [Issue 82](https://code.google.com/p/autoblock/issues/detail?id=82) Allow setting to enable parsing 3 letter keywords
  * [Issue 139](https://code.google.com/p/autoblock/issues/detail?id=139) Implement option to remove punctuation before keyword parsing
  * [Issue 140](https://code.google.com/p/autoblock/issues/detail?id=140) Auto-trigger multiselect mode in keywords pane

v3.3.0.0:
  * [Issue 13](https://code.google.com/p/autoblock/issues/detail?id=13) Add new assets
  * [Issue 17](https://code.google.com/p/autoblock/issues/detail?id=17) Integrate call blocking feature
  * [Issue 89](https://code.google.com/p/autoblock/issues/detail?id=89) Do not allow any read/write operations on UI until the database is created
  * [Issue 92](https://code.google.com/p/autoblock/issues/detail?id=92) Show a spinner slider when the database is still being set up
  * [Issue 94](https://code.google.com/p/autoblock/issues/detail?id=94) Let the service tell the UI when it is ready
  * [Issue 126](https://code.google.com/p/autoblock/issues/detail?id=126) Implement error recovery
  * [Issue 127](https://code.google.com/p/autoblock/issues/detail?id=127) Setup code is doing a lot of unnecessary i/o
  * [Issue 129](https://code.google.com/p/autoblock/issues/detail?id=129) Implement in-app review feature
  * [Issue 131](https://code.google.com/p/autoblock/issues/detail?id=131) Change all replacement insertions with ignores
  * [Issue 132](https://code.google.com/p/autoblock/issues/detail?id=132) Some spammers do not specify a valid email address and a blank email address fails insertion
  * [Issue 133](https://code.google.com/p/autoblock/issues/detail?id=133) Do not allow null or empty strings into keywords or addresses database
  * [Issue 134](https://code.google.com/p/autoblock/issues/detail?id=134) Don't allow empty addresses to be selected in conversations tab
  * [Issue 135](https://code.google.com/p/autoblock/issues/detail?id=135) Implement recovery of corrupted databases

v3.0.0.0:
  * [Issue 32](https://code.google.com/p/autoblock/issues/detail?id=32)	[Add-On](Paid.md): Feature: Scan sender name & address for keywords
  * [Issue 43](https://code.google.com/p/autoblock/issues/detail?id=43)	[Add-on](Paid.md): Move spam to the Trash folder instead of permanent deletion
  * [Issue 44](https://code.google.com/p/autoblock/issues/detail?id=44)	[Enhancement](Enhancement.md) Use a slide-out menu for "Add Keywords" instead of toast
  * [Issue 68](https://code.google.com/p/autoblock/issues/detail?id=68)	Transaction fails if you try to insert to the database too many items
  * [Issue 71](https://code.google.com/p/autoblock/issues/detail?id=71)	Syncing fails if the user has a large local database
  * [Issue 73](https://code.google.com/p/autoblock/issues/detail?id=73)	[Feature](Feature.md) Allow user to freely enter any keywords they wish without restrictions
  * [Issue 81](https://code.google.com/p/autoblock/issues/detail?id=81)	[Enhancement](Enhancement.md): Group keyword picker and reported spammers list
  * [Issue 83](https://code.google.com/p/autoblock/issues/detail?id=83)	[Feature](Feature.md) Implement search field in the Blocked tab
  * [Issue 84](https://code.google.com/p/autoblock/issues/detail?id=84)	[Feature](Feature.md) Implement Search field in Keywords tab
  * [Issue 85](https://code.google.com/p/autoblock/issues/detail?id=85)	[Feature](Feature.md) Implement search field in the Logs tab
  * [Issue 90](https://code.google.com/p/autoblock/issues/detail?id=90)	Remove Select All action from element picker screen
  * [Issue 91](https://code.google.com/p/autoblock/issues/detail?id=91)	Look up using third index for message ID when invoked
  * [Issue 93](https://code.google.com/p/autoblock/issues/detail?id=93)	Monitor the file system to determine when the database file is created instead of using a timer
  * [Issue 95](https://code.google.com/p/autoblock/issues/detail?id=95)	[Enhancement](Enhancement.md) When the user submits a bug report, copy the bug ID to the clipboard
  * [Issue 96](https://code.google.com/p/autoblock/issues/detail?id=96)	Improve logging
  * [Issue 97](https://code.google.com/p/autoblock/issues/detail?id=97)	[Performance](Performance.md) Don't refresh UI on unnecessary persistent storage updates
  * [Issue 98](https://code.google.com/p/autoblock/issues/detail?id=98)	Integrate with tutorial API
  * [Issue 100](https://code.google.com/p/autoblock/issues/detail?id=100)	The "Block" action enabled state is not reset after a block happens and the user switches the account dropdown
  * [Issue 101](https://code.google.com/p/autoblock/issues/detail?id=101)	[Feature](Feature.md): Allow user to enter text when submitting logs
  * [Issue 103](https://code.google.com/p/autoblock/issues/detail?id=103)	[Feature](Feature.md) Implement setting to let user choose default tab
  * [Issue 104](https://code.google.com/p/autoblock/issues/detail?id=104)	Text with newline characters show up incorrectly in the logs screen
  * [Issue 105](https://code.google.com/p/autoblock/issues/detail?id=105)	[Feature](Feature.md): Exclude common words from showing up in the keyword parsing
  * [Issue 107](https://code.google.com/p/autoblock/issues/detail?id=107)	Validate email address before adding it
  * [Issue 109](https://code.google.com/p/autoblock/issues/detail?id=109)	Add icon to Update action
  * [Issue 110](https://code.google.com/p/autoblock/issues/detail?id=110)	Reuse progress bar when user is submitting logs
  * [Issue 111](https://code.google.com/p/autoblock/issues/detail?id=111)	If the user does not have any elements in the blocked list and they try to update it doesn't work
  * [Issue 112](https://code.google.com/p/autoblock/issues/detail?id=112)	[Performance](Performance.md) Use new optimized syncing when updating with server to minimize device data
  * [Issue 114](https://code.google.com/p/autoblock/issues/detail?id=114)	[Enhancement](Enhancement.md): Long addresses and keywords get truncated in the picker page
  * [Issue 116](https://code.google.com/p/autoblock/issues/detail?id=116)	[Feature](Feature.md) Implement backup & restore
  * [Issue 117](https://code.google.com/p/autoblock/issues/detail?id=117)	[Enhancement](Enhancement.md) Merge the Add Email Address and Add SMS Sender flows into one
  * [Issue 118](https://code.google.com/p/autoblock/issues/detail?id=118)	[Feature](Feature.md) Implement database optimizer
  * [Issue 119](https://code.google.com/p/autoblock/issues/detail?id=119)	UI behaves unexpectedly if the database is being prepared on first launch
  * [Issue 120](https://code.google.com/p/autoblock/issues/detail?id=120)	After the last message is blocked from an account in the Conversations tab, the empty placeholder doesn't show up
  * [Issue 121](https://code.google.com/p/autoblock/issues/detail?id=121)	[Enhancement](Enhancement.md) Trigger multiselect mode when a blocked address is tapped in Blocked tab
  * [Issue 122](https://code.google.com/p/autoblock/issues/detail?id=122)	[Enhancement](Enhancement.md) Group keywords by first character in Keywords tab
  * [Issue 124](https://code.google.com/p/autoblock/issues/detail?id=124)	Scroll Logs pane list to the beginning when a new message is blocked
  * [Issue 125](https://code.google.com/p/autoblock/issues/detail?id=125)	Manual keyword addition capitalizes first letter automatically

v2.7.0.0:
  * [Issue	65](https://code.google.com/p/autoblock/issues/detail?id=65)	General code cleanup and refactoring
  * [Issue	73](https://code.google.com/p/autoblock/issues/detail?id=73)	Allow user to freely enter any keywords they wish without restrictions
  * [Issue	74](https://code.google.com/p/autoblock/issues/detail?id=74)	Implement better bug-reporting
  * [Issue	75](https://code.google.com/p/autoblock/issues/detail?id=75)	Bug reports are not being prepared when database transactions failed
  * [Issue	77](https://code.google.com/p/autoblock/issues/detail?id=77)	App sometimes shows blank addresses being blocked when invoked via Share Framework through BlackBerry Hub
  * [Issue	78](https://code.google.com/p/autoblock/issues/detail?id=78)	Log file name should be based on the process type
  * [Issue	79](https://code.google.com/p/autoblock/issues/detail?id=79)	Clean up database on first launch
  * [Issue	80](https://code.google.com/p/autoblock/issues/detail?id=80)	App keeps showing successful toast even when transactions fail

v2.5.1.0:
  * [Issue 69](https://code.google.com/p/autoblock/issues/detail?id=69)	Keyword lookups are still being processed after logged transactions
  * [Issue 70](https://code.google.com/p/autoblock/issues/detail?id=70)	Allow turning on verbose logging

v2.5.0.0:
  * [Issue 60](https://code.google.com/p/autoblock/issues/detail?id=60)	10-letter keywords do not get added
  * [Issue 61](https://code.google.com/p/autoblock/issues/detail?id=61)	Lookups are case sensitive
  * [Issue 62](https://code.google.com/p/autoblock/issues/detail?id=62)	Show download progress for Update
  * [Issue 63](https://code.google.com/p/autoblock/issues/detail?id=63)	Show prompt when performing updates
  * [Issue 64](https://code.google.com/p/autoblock/issues/detail?id=64)	Keywords list and Blocked Senders list can take a while to render if you scroll really fast
  * [Issue 65](https://code.google.com/p/autoblock/issues/detail?id=65)	General code cleanup and refactoring
  * [Issue 66](https://code.google.com/p/autoblock/issues/detail?id=66)	Blocked tab was loading by default
  * [Issue 67](https://code.google.com/p/autoblock/issues/detail?id=67)	Implement diagnostic reporting

v2.3.0.0:
  * [Issue 51](https://code.google.com/p/autoblock/issues/detail?id=51)	Automatically delete an email once it has been tagged as spam in the UI
  * [Issue 52](https://code.google.com/p/autoblock/issues/detail?id=52)	4-letter keywords do not work
  * [Issue 53](https://code.google.com/p/autoblock/issues/detail?id=53)	Implement setting to toggle whether to skip contact list check or not
  * [Issue 54](https://code.google.com/p/autoblock/issues/detail?id=54)	If there are no blocked senders and only a single keyword is added, then the app starts deleting random emails
  * [Issue 55](https://code.google.com/p/autoblock/issues/detail?id=55)	Keywords matching is not implemented for SMS messages
  * [Issue 56](https://code.google.com/p/autoblock/issues/detail?id=56)	Dismiss Add Keywords toast on touch
  * [Issue 57](https://code.google.com/p/autoblock/issues/detail?id=57)	Prompt user to see video tutorial
  * [Issue 58](https://code.google.com/p/autoblock/issues/detail?id=58)	Spam list update picker takes a long time to render addresses if you scroll really fast

v2.1.0.0:
  * [Issue 45](https://code.google.com/p/autoblock/issues/detail?id=45)	Keywords Picker page always shows up after block action
  * [Issue 47](https://code.google.com/p/autoblock/issues/detail?id=47)	Quitting app while messages are loading greys out app icon
  * [Issue 48](https://code.google.com/p/autoblock/issues/detail?id=48)	Add icons for all toasts
  * [Issue 49](https://code.google.com/p/autoblock/issues/detail?id=49)	Implement BBM Channel link

v2.0.0.0:
  * [Issue 1](https://code.google.com/p/autoblock/issues/detail?id=1)	Integrate app with Canada Inc Library
  * [Issue 14](https://code.google.com/p/autoblock/issues/detail?id=14)	Add sharing functionality for spam list
  * [Issue 16](https://code.google.com/p/autoblock/issues/detail?id=16)	Use a single MessageManager instead of 1 per account.
  * [Issue 18](https://code.google.com/p/autoblock/issues/detail?id=18)	Use custom freeform TitleBar to give more real-estate for scrolling the message list
  * [Issue 19](https://code.google.com/p/autoblock/issues/detail?id=19)	Implement log sheet
  * [Issue 20](https://code.google.com/p/autoblock/issues/detail?id=20)	Implement keyword filtering algorithm
  * [Issue 22](https://code.google.com/p/autoblock/issues/detail?id=22)	Add tutorials to help users understand all the features
  * [Issue 24](https://code.google.com/p/autoblock/issues/detail?id=24)	Add as share invocation target
  * [Issue 25](https://code.google.com/p/autoblock/issues/detail?id=25)	Change root to be a TabbedPane
  * [Issue 26](https://code.google.com/p/autoblock/issues/detail?id=26)	Add as plaint-text Share invoke target
  * [Issue 27](https://code.google.com/p/autoblock/issues/detail?id=27)	Update assets
  * [Issue 29](https://code.google.com/p/autoblock/issues/detail?id=29)	Use a database for lookups instead of data structure
  * [Issue 33](https://code.google.com/p/autoblock/issues/detail?id=33)	blocks mail not in list
  * [Issue 35](https://code.google.com/p/autoblock/issues/detail?id=35)	Add time limit restriction for loading messages
  * [Issue 36](https://code.google.com/p/autoblock/issues/detail?id=36)	Make the account picker dropdown persistent
  * [Issue 37](https://code.google.com/p/autoblock/issues/detail?id=37)	Make app Q10/Q5 friendly
  * [Issue 38](https://code.google.com/p/autoblock/issues/detail?id=38)	Use multiselect mode for list selections instead of tapping one by one
  * [Issue 39](https://code.google.com/p/autoblock/issues/detail?id=39)	Add whitelist contacts setting
  * [Issue 41](https://code.google.com/p/autoblock/issues/detail?id=41)	Changing accounts while messages are loading causes progress bar flickering
  * [Issue 42](https://code.google.com/p/autoblock/issues/detail?id=42)	Implement headless service

v1.5.1.0:
  * [Issue 21](https://code.google.com/p/autoblock/issues/detail?id=21): If user had more than 1 entry in the blocked list, spammers could not be unblocked.

v1.5.0.1:
  * [Issue #1](https://code.google.com/p/autoblock/issues/detail?id=#1): Integrate app with Canada Inc Library.
  * [Issue #2](https://code.google.com/p/autoblock/issues/detail?id=#2): App does not always match the spammer if the BB10 OS appends a 1 in front of the number.
  * [Issue #3](https://code.google.com/p/autoblock/issues/detail?id=#3): Assets need to be loaded asynchronously.
  * [Issue #4](https://code.google.com/p/autoblock/issues/detail?id=#4): New feature: Support for emails and multiple accounts.
  * [Issue #5](https://code.google.com/p/autoblock/issues/detail?id=#5): Remove animations setting
  * [Issue #6](https://code.google.com/p/autoblock/issues/detail?id=#6): Remove the "Active Mode" and always turn on spam blocking upon
startup. Remove "active" state from cover.
  * [Issue #8](https://code.google.com/p/autoblock/issues/detail?id=#8): Add bug-report.
  * [Issue #9](https://code.google.com/p/autoblock/issues/detail?id=#9): Validate permissions.
  * [Issue #10](https://code.google.com/p/autoblock/issues/detail?id=#10): Lag when trying to fetch SMS conversations.
  * [Issue #11](https://code.google.com/p/autoblock/issues/detail?id=#11): Switch to a faster lookup data structure.
  * [Issue #12](https://code.google.com/p/autoblock/issues/detail?id=#12): Software engineering: Restructure UI and model relationship. Pngcrush images.
  * [Issue 15](https://code.google.com/p/autoblock/issues/detail?id=15): Maintain global blocked count.
  * Bug reports is now integrated into the app.
  * Battery saving by only animating arrows on startup.

v1.1.0.1:
-Critical Bug-fix: App would not be blocking messages when backgrounded (when LCD was off).
-Refactor in design and performance improvements to decrease startup time.
-Bug-fix: Contacts with no avatars would not show up properly in list.
-Live tile cover UI refresh.

v1.0.0.1 (Initial release):
  * Animation toggling, monitor on startup settings.
  * Arrow animation when monitoring.
  * Spam sender selection only on existing messages.
  * Support for Q10 and Z10.
  * Live tile cover shows number of blocked messages so far.