> We are making a very simple neovim plugin called `copy-context` that when invoked
will copy a reference to the current file or file and selected lines in the
format needed for an AI agent to work with.

>For example, if i am working in a file in my project called `src/main.py` and use
the keybinding, my clipboard will now have `@src/main.py` so i can quickly paste
it to an AI agent session.

>If i have a visual selection, we will copy the context including the selected
line numbers. So if I have selected lines 5 through 10 in `src/main.py`, when i
invoke the keybinding the clipboard will now contain `@src/main.py#L5-10`. If i
only have one line selected, simply only reference that line like
`@src/main.py#L5`.

>Make this plugin loadable via lazyvim. The name of the git repo it is in is
`mpiannucci/copy-
context`
