type t = {
  in_chan : In_channel.t;
  out_chan : Out_channel.t;
  n_programs : int;
}

type runner_option = 
  | WithController of t
  | NoController

val init : unit -> runner_option

val terminate : runner_option -> unit

val get_n_programs : runner_option -> int option
