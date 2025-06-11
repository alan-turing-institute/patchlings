type t = {
  in_chan : In_channel.t;
  out_chan : Out_channel.t;
}

val init : unit -> t

val terminate : t -> unit
