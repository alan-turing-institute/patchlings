use std::env;
use std::process;

extern "C" {
    fn take_turn(input1: u64, input2: u64) -> u32;
}

fn main() {
    let arg = env::args().nth(1).expect("Expected one argument");
    if arg.len() > 16 {
        eprintln!("Input must be at most 16 characters long");
        process::exit(1);
    }

    // Convert the string to bytes and pad with zeros if necessary
    let mut bytes = [0u8; 16];
    bytes[..arg.len()].copy_from_slice(arg.as_bytes());

    // Convert each part of the byte array to u64
    let input1 = u64::from_be_bytes(bytes[0..8].try_into().expect("Slice with incorrect length"));
    let input2 = u64::from_be_bytes(bytes[8..16].try_into().expect("Slice with incorrect length"));

    // Call the external function with the two u64 values
    let result = unsafe { take_turn(input1, input2) };
    println!("{}", result);
    process::exit(0);
}
