# replacer
Replacer is a very simple tool written in Rust that takes a list of words and slaps those words into a string of your choice.

I primarily use it when I need to mass-generate things. Such as queries and what not.

## Example
Place a `words.txt` in the root folder.

### words.txt
```
three
cool
words
```

Run the program with a string you want to replace something in:
```
cargo run -- "Hello, my name is %rep"
```

An `output.txt` will then be created in the root folder:

### output.txt
```
Hello, my name is three
Hello, my name is cool
Hello, my name is words
```

That's all it does.