type t = {
  in_chan : In_channel.t;
  out_chan : Out_channel.t;
  n_programs : int;
  player_names : string list;
}

type runner_option = 
  | WithController of t
  | NoController

let init () =
  let cwd = Unix.getcwd () in
  let controller_binary = cwd ^ "/controller/target/release/controller" in
  let asm_path = cwd ^ "/asm" in
  let wrapper_path = cwd ^ "/wrapper" in
  (* check that controller binary exists *)
  if not (Sys.file_exists controller_binary) then begin
    Printf.eprintf "\n⚠️  WARNING: Controller binary not found at %s\n" controller_binary;
    Printf.eprintf "Running in test mode without external controller.\n";
    Printf.eprintf "To use external controller, run: cd controller; cargo build --release\n\n";
    NoController
  end else
    let process_str =
      String.concat " " [ controller_binary; asm_path; wrapper_path ]
    in
    let in_chan, out_chan = Unix.open_process process_str in
    In_channel.set_binary_mode in_chan false;
    Out_channel.set_binary_mode out_chan false;
    (* Read the number of programs from the controller *)
    match In_channel.input_line in_chan with
    | Some n_str -> (
        try
          let n_programs = int_of_string n_str in
          Printf.printf "Controller reports %d assembly programs available\n" n_programs;
          
          (* Read the player names *)
          let rec read_names acc count =
            if count <= 0 then List.rev acc
            else
              match In_channel.input_line in_chan with
              | Some name -> read_names (name :: acc) (count - 1)
              | None -> 
                  Printf.eprintf "Failed to read all player names\n";
                  List.rev acc
          in
          let player_names = read_names [] n_programs in
          Printf.printf "Player names: %s\n" (String.concat ", " player_names);
          
          WithController { in_chan; out_chan; n_programs; player_names }
        with _ ->
          Printf.eprintf "Failed to parse program count from controller\n";
          NoController
      )
    | None ->
        Printf.eprintf "Controller failed to report program count\n";
        NoController

let terminate runner =
  match runner with
  | WithController t ->
      (* src/main.rs parses the "exit" command to terminate gracefully *)
      Out_channel.output_string t.out_chan "exit\n";
      Out_channel.close t.out_chan;
      In_channel.close t.in_chan;
      let _ = Unix.close_process (t.in_chan, t.out_chan) in
      ()
  | NoController -> ()

let get_n_programs runner =
  match runner with
  | WithController t -> Some t.n_programs
  | NoController -> None

let get_player_names runner =
  match runner with
  | WithController t -> Some t.player_names
  | NoController -> None
