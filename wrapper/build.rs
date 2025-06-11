use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::Command;

fn main() {
    let asm_file = env::var("ASM_FILE").expect("ASM_FILE not set");
    let out_bin = env::var("OUT_BIN").expect("OUT_BIN not set");

    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    let obj_file = out_dir.join("temp.o");

    // Compile ASM to object file
    let status = Command::new("clang")
        .args(["-c", &asm_file, "-o"])
        .arg(&obj_file)
        .status()
        .expect("Failed to compile ASM");

    if !status.success() {
        panic!("clang failed to compile {}", asm_file);
    }

    // Tell Cargo to pass this object file to the linker
    println!("cargo:rustc-link-arg={}", obj_file.display());

    // We also need to ensure the final binary is copied to OUT_BIN manually
    // (we'll do this from the controller after the build)
}
