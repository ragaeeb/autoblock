# Introduction #

This page outlines a preliminary smoke test for Auto Block.


# SMS Test #

  1. SMS\_Test: Receive MMS from A to DUT, ensure message shows up in the Conversations tab.
  1. Select conversation and hit "Block", ensure address shows up in Blocked tab.
  1. Ensure "Add Keywords" slides out.
  1. Add two keywords and ensure they show up in the Keywords tab.
  1. Send SMS again to DUT from sender and ensure that message is blocked.
  1. Minimize app, make sure the active frame updates to show the last sender that was blocked.
  1. Go to Logs tab, ensure the blocked tab shows the blocked message.

# SMS Keyword Test #
  1. Press-and-hold on the blocked sender, delete it from the Blocked tab.
  1. Send SMS again to DUT from sender and ensure that message is not blocked.
  1. Send SMS again to DUT from sender with a bad keyword and ensure message is blocked.

# Placeholder Test #
  1. Go to Conversations tab, load an account with no messages and ensure placeholder shows.
  1. Switch to an email account with more than 1 conversation, and block 2 (all) senders so nothing remains. Ensure placeholder shows.