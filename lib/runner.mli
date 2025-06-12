type t = {
  in_chan : In_channel.t;
  out_chan : Out_channel.t;
  n_programs : int;
  player_names : string list;
}

type runner_option = 
  | WithController of t
  | NoController

val init : unit -> runner_option

val terminate : runner_option -> unit

val get_n_programs : runner_option -> int option

val get_player_names : runner_option -> string list option
