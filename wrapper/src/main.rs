use std::env;
use std::process;

extern "C" {
    fn take_turn(input: u32) -> u32;
}

fn main() {
    let arg = env::args().nth(1).expect("Expected one argument");
    let input: u32 = arg.parse().expect("Invalid integer argument");

    let result = unsafe { take_turn(input) };
    println!("{}", result);
    process::exit(0);
}
