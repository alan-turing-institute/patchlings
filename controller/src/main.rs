use rayon::prelude::*;
use std::collections::HashMap;
use std::env::args;
use std::fs;
use std::io::{self, Read};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use wait_timeout::ChildExt;

fn main() {
    let asm_dir = args().nth(1).unwrap();
    let wrapper_dir = args().nth(2).unwrap();
    let debug = args().nth(3).is_some();
    let asm_dir = Path::new(&asm_dir);
    let asm_files: Vec<PathBuf> = fs::read_dir(asm_dir)
        .expect("error reading asm_dir")
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .filter(|p| p.extension().map_or(false, |ext| ext == "s"))
        .collect();

    fs::create_dir_all("build").unwrap();

    if debug {
        println!("Building wrappers...")
    };
    let mut binary_paths = Vec::new();
    for asm_path in &asm_files {
        let filename = asm_path.file_stem().unwrap().to_string_lossy().to_string();
        let output_path = Path::new("build").join(format!("{filename}.bin"));
        if output_path.exists() {
            if debug {
                println!("{:<20} -> Using cached binary", filename);
            }
            binary_paths.push((filename, output_path));
        } else {
            if let Some(bin_path) = build_wrapper(&wrapper_dir, asm_path, output_path, debug) {
                binary_paths.push((filename, bin_path));
            } else {
                if debug {
                    println!("{:<20} -> Build failed", filename);
                }
            }
        }
    }

    // Send the number of players and their names to the OCaml game
    println!("{}", binary_paths.len());
    
    // Sort binary_paths by filename (numeric order)
    binary_paths.sort_by_key(|(filename, _)| {
        u32::from_str_radix(filename, 10).unwrap_or(0)
    });
    
    // Send each player name on a separate line
    for (filename, _) in &binary_paths {
        println!("{}", filename);
    }

    loop {
        let mut buf = String::new();
        io::stdin().read_line(&mut buf).unwrap();

        if buf.trim() == "exit" {
            break;
        }

        fn inputs_of_buf(buf: String) -> HashMap<usize, String> {
            HashMap::from_iter(buf.trim().split(",").map(|s| s.to_owned()).enumerate())
        }

        let inputs = inputs_of_buf(buf.clone());

        let mut results: Vec<(String, Option<u8>)> = binary_paths
            .iter()
            .map(|(filename, path)| {
                let input = inputs
                    .get(&usize::from_str_radix(filename, 10).expect("asm filenames must be int"))
                    .expect("couldn't find input for asm file");
                let result = run_wrapper(path, input, debug);
                (filename.clone(), result)
            })
            .collect();

        if debug {
            for (filename, result) in results {
                println!("{:<20} -> {:?}", filename, result);
            }
        } else {
            results.sort_by_key(|(id, _)| {
                u32::from_str_radix(id, 10).expect("asm file names must be ints")
            });
            fn to_score(score_opt: &Option<u8>) -> String {
                match score_opt {
                    None => String::from("_,"),
                    Some(n) => format!("{},", *n as char),
                }
            }
            let out = results
                .iter()
                .fold(String::new(), |acc, (_, res)| acc + &to_score(res));
            println!("{}", out.strip_suffix(",").unwrap());
        }
    }
}

fn build_wrapper(
    wrapper_dir: &str,
    asm_path: &Path,
    output_path: PathBuf,
    debug: bool,
) -> Option<PathBuf> {
    let wrapper_dir = Path::new(wrapper_dir);

    // Clean previous build
    let _ = Command::new("cargo")
        .args(["clean"])
        .current_dir(wrapper_dir)
        .output();

    // Build the wrapper with the .s file and desired output path
    let output = Command::new("cargo")
        .args(["build", "--release"])
        .current_dir(wrapper_dir)
        .env("ASM_FILE", asm_path)
        .env("OUT_BIN", &output_path)
        .output()
        .ok()?;

    if !output.status.success() {
        if debug {
            eprintln!(
                "Failed to compile wrapper for {}:\n{}",
                asm_path.display(),
                String::from_utf8_lossy(&output.stderr)
            );
        }
        return None;
    }

    // Copy the binary Cargo built
    let built_path = wrapper_dir.join("target/release/wrapper");
    std::fs::copy(&built_path, &output_path).ok()?;

    Some(output_path)
}

fn run_wrapper(path: &Path, input: &str, debug: bool) -> Option<u8> {
    let mut child = Command::new(path)
        .arg(input)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .ok()?;

    let timeout = std::time::Duration::from_secs(3);
    match child.wait_timeout(timeout).ok()? {
        Some(status) if status.success() => {
            let mut stdout = String::new();
            child.stdout.as_mut()?.read_to_string(&mut stdout).ok()?;
            stdout.trim().parse::<u8>().ok()
        }
        Some(status) => {
            let mut stderr = String::new();
            child.stderr.as_mut()?.read_to_string(&mut stderr).ok()?;
            if debug {
                eprintln!(
                    "Wrapper process failed for {} (code {:?}):\n{}",
                    path.display(),
                    status.code(),
                    stderr
                );
            }
            None
        }
        None => {
            let _ = child.kill();
            if debug {
                eprintln!("Timeout reached for wrapper process: {}", path.display());
            }
            None
        }
    }
}
