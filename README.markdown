# ShBuffer

> Execute selected shell command and return the result in a scratch buffer

### How To:

It's easy:
- Visually select some shell code, or don't and the whole file will be used
- `:ShBuffer`
- Optionally map it to something sweet, like `map <leader>s :ShBuffer <cr>`

### Example:

````
echo "one two three"
````

Will create a new scratch buffer containing:

````
one two three
````

### Oops, it's broken

ShBuffer relies on $SHELL being set.  It should already be, but if it's not: `export $SHELL /bin/bash`
