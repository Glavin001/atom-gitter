[atom-gitter](https://github.com/Glavin001/atom-gitter)
===========

[![Gitter chat](https://badges.gitter.im/Glavin001/atom-gitter.png)](https://gitter.im/Glavin001/atom-gitter)

> [Gitter chat](https://gitter.im/) integration with [Atom.io](https://atom.io/).


| Open | Closed |
| --- | ---- |
| ![](https://raw.githubusercontent.com/Glavin001/atom-gitter/master/screenshots/panel_open.png) | ![](https://raw.githubusercontent.com/Glavin001/atom-gitter/master/screenshots/panel_closed.png) |

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

## Package Settings

- `Open On New Message` - On receiving a new message,
    force open the messages panel.
- `Recent Messages At Top` - Order of displaying the messages.
    If true, the most recent message will be at the top.
- `Token` - Your Gitter Personal Access Token.
