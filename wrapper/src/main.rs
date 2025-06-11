use std::env;
use std::process;

extern "C" {
    fn take_turn(input: u64) -> u32;
}

fn main() {
    let arg = env::args().nth(1).expect("Expected one argument");
    if arg.len() != 8 {
        eprintln!("Input must be exactly 8 characters long");
        process::exit(1);
    }
    let bytes = arg.as_bytes();
    let input = u64::from_be_bytes(bytes.try_into().expect("Slice with incorrect length"));

    let result = unsafe { take_turn(input) };
    println!("{}", result);
    process::exit(0);
}
