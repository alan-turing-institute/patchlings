type t = {
  in_chan : In_channel.t;
  out_chan : Out_channel.t;
}

let init () =
  let cwd = Unix.getcwd () in
  let controller_binary = cwd ^ "/controller/target/release/controller" in
  let asm_path = cwd ^ "/asm" in
  let wrapper_path = cwd ^ "/wrapper" in
  let process_str =
    String.concat " " [ controller_binary; asm_path; wrapper_path ]
  in
  let in_chan, out_chan = Unix.open_process process_str in
  In_channel.set_binary_mode in_chan false;
  Out_channel.set_binary_mode out_chan false;
  { in_chan; out_chan }

let terminate t =
  (* src/main.rs parses the "exit" command to terminate gracefully *)
  Out_channel.output_string t.out_chan "exit\n";
  Out_channel.close t.out_chan;
  In_channel.close t.in_chan;
  let _ = Unix.close_process (t.in_chan, t.out_chan) in
  ()
