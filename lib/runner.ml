type t = {
  in_chan : In_channel.t;
  out_chan : Out_channel.t;
}

let init () =
  let in_chan, out_chan = Unix.open_process "controller" in
  In_channel.set_binary_mode in_chan false;
  Out_channel.set_binary_mode out_chan false;
  {in_chan; out_chan}
