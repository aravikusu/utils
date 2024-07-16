use std::env;
use std::process;

fn main() -> std::io::Result<()> {
    let string = replacer::get_args(env::args()).unwrap_or_else(|err| {
        eprintln!("{err}");
        process::exit(1);
    });

    replacer::replace(string).unwrap_or_else(|err| {
        eprintln!("Something went wrong: {err}");
    });

    println!("Success.");
    process::exit(1);
}
