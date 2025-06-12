type align = 
  | Start
  | Centre
  | End

val fg : int -> string -> string
val bg : int -> string -> string
val bold : string -> string
val get_width : string -> int
val get_height : string -> int
val vcat : ?sep:string -> align -> string list -> string
val hcat : ?sep:string -> align -> string list -> string
val box : ?padding:int -> string -> string
