use std::{error::Error, fs};


pub fn get_args(mut args: impl Iterator<Item=String>) -> Result<String, &'static str> {
    args.next();

    let string = match args.next() {
        Some(arg) => arg,
        None => return Err("You must supply a string we can work with."),
    };

    Ok(string)
}

pub fn replace(string: String) -> Result<(), Box<dyn Error>> {
    let words = fs::read_to_string("words.txt")
        .expect("Could not find words.txt. Place it in the folder root.");

    let mut final_string = String::new();
    for word in words.lines() {
        let replaced = string.replace("%rep", word) + "\n";
        final_string.push_str(&replaced);
    }

    fs::write("output.txt", final_string).unwrap_or_else(|err| {
        eprintln!("Could not write output.txt: {}", err);
    });

    Ok(())
}