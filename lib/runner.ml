let init () =
  let in_chan, out_chan = Unix.open_process "controller" in
  In_channel.set_binary_mode in_chan false;
  Out_channel.set_binary_mode out_chan false;

  (* Out_channel.output_string out_chan "hello\n"; *)
  (* Out_channel.flush out_chan; *)
  let rec read_all chan =
    match In_channel.input_line in_chan with
    | None -> ()
    | Some ln ->
        print_endline ln;
        read_all chan
  in
  read_all in_chan
