[atom-gitter](https://github.com/Glavin001/atom-gitter)
===========

[![Gitter chat](https://badges.gitter.im/Glavin001/atom-gitter.png)](https://gitter.im/Glavin001/atom-gitter)

> [Gitter chat](https://gitter.im/) integration with [Atom.io](https://atom.io/).

-----

## Install

Atom Package: https://atom.io/packages/gitter

```bash
apm install gitter
```

Or Settings/Preferences ➔ Packages ➔ Search for `gitter`

Then go to https://developer.gitter.im/apps and retrieve your *Personal Access Token*.  
Enter your Token in the Package Settings.
Go to Settings/Preferences ➔ Search for installed package `gitter` ➔ Enter your `Token`.

## Features

- [x] Automatically detect the room using the Git repository remote URL
- [x] Listen and display new messages
- [x] Posting message
- [x] [Send selected code](https://github.com/Glavin001/atom-gitter/issues/14)
- [x] [Emoji support in messages](http://www.emoji-cheat-sheet.com/)
- [x] [Support to switch and join other rooms](https://github.com/Glavin001/atom-gitter/issues/10)

| Open | Closed |
| --- | ---- |
| ![](https://raw.githubusercontent.com/Glavin001/atom-gitter/master/screenshots/panel_open.png) | ![](https://raw.githubusercontent.com/Glavin001/atom-gitter/master/screenshots/panel_closed.png) |

| Send Selected Code |
| --- |
| ![](https://cloud.githubusercontent.com/assets/1885333/3281620/ea6c00b0-f4b9-11e3-85a3-41eadfefa8d8.gif) |


## Package Settings

- `Token` - Your Gitter Personal Access Token.
- `Open On New Message` - On receiving a new message,
    force open the messages panel.
- `Recent Messages At Top` - Order of displaying the messages.
    If true, the most recent message will be at the top.
- `Display Snapshot Messages` - After joining a group,
    display a snapshot of the previous messages.

## Keyboard Shortcuts & Commands

By default, there are no existing keyboard shortcuts.
See [issue for discussion about default keyboard shortcuts](https://github.com/Glavin001/atom-gitter/issues/18).

To add your own custom keyboard shortcuts, go to `Atom` ➔ `Open Your Keymap`.

- `gitter:toggle-compose-message` - Toggle (open/close) the top panel to compose a new message.
- `gitter:send-selected-code` - Send the currently selected source code over Gitter.
- `gitter:send-message` - Send the current message in the compose panel.
- `gitter:open-messages` - Open the Messages panel.
- `gitter:close-messages` - Close the Messages panel.
- `gitter:restart` - Restart Gitter, including logging in and joining the project room.
- `gitter:clear-messages` - Clear all messages.
- `gitter:toggle-messages` - Toggle (open/close) the bottom panel for displaying all messages.
- `gitter:switch-room` - Open input for entering a new room URI to switch into.

See [Keymaps In-Depth](https://atom.io/docs/latest/advanced/keymaps) for more details.

### Example

For example, this is [@Glavin001](https://github.com/Glavin001)'s personal `keymap.cson` for Atom.

```Coffeescript
'.editor': # Available from Editor only
  'cmd-ctrl-c': 'gitter:send-selected-code'
'.workspace': # Available Globally
  'cmd-ctrl-x': 'gitter:toggle-compose-message'
  'cmd-ctrl-z': 'gitter:switch-room'
'.gitter.panel': # Available from within the Gitter compose message panel
  'cmd-ctrl-s': 'gitter:send-message'
```
