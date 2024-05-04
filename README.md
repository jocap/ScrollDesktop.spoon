Scrollable window manager for Mac OS X.  With the pointer above the
desktop or the Command key pressed, scroll left or right to move
windows across a virtual infinitely wide horizontal plane.

When Shift is held, the window under the cursor stays in place.  When
Option is held, only the window under the pointer is scrolled.  When
Control is held, only the windows to the right of the cursor are
scrolled.

ScrollDesktop is a plugin for [Hammerspoon] and is inspired by
[PaperWM.spoon].

[Hammerspoon]: https://www.hammerspoon.org/
[PaperWM.spoon]: https://github.com/mogenson/PaperWM.spoon

https://github.com/jocap/ScrollDesktop.spoon/assets/92702/c434a79b-3885-46b6-af8c-e73f0fa17a8c

### Configuration

To install ScrollDesktop, run the following shell command:

```sh
git clone git@github.com:jocap/ScrollDesktop.spoon.git ~/.hammerspoon/Spoons/ScrollDesktop.spoon
```

To enable ScrollDesktop, put the following in `~/.hammerspoon/init.lua`:

```lua
ScrollDesktop = hs.loadSpoon("ScrollDesktop")
ScrollDesktop:start()
```

The `start` function takes an optional table of options:

* `{everywhere = true}`: Enable scrolling everywhere, without needing
  to hold a modifier key.  (Hold Command to temporarily disable scrolling.)
