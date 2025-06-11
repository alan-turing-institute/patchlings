open Wcwidth

type align =
  | Start
  | Centre
  | End

let get_width (s : string) : int =
  String.split_on_char '\n' s
  |> List.fold_left (fun acc line -> max acc (wcswidth line)) 0

let get_height (s : string) : int =
  String.fold_left (fun acc c -> if c = '\n' then acc + 1 else acc) 1 s

let vcat ?(sep : string = "\n") (align : align) (blocks : string list) =
  let widths = List.map get_width blocks in
  let max_width = List.fold_left max 0 widths in
  let pad_space (n : int) (s : string) =
    let start = String.make n ' ' in
    s |> String.split_on_char '\n'
    |> List.map (fun s -> start ^ s)
    |> String.concat "\n"
  in
  List.map2
    (fun this_block_width bl ->
      let padding =
        match align with
        | Start -> 0
        | Centre -> (max_width - this_block_width) / 2
        | End -> max_width - this_block_width
      in
      pad_space padding bl)
    widths blocks
  |> String.concat sep

let hcat ?(sep : string = " ") (align : align) (blocks : string list) =
  let heights = List.map get_height blocks in
  let widths = List.map get_width blocks in
  let max_height = List.fold_left max 0 heights in
  let pad_newline (n : int) (s : string) = String.make n '\n' ^ s in
  let padded_blocks =
    List.map2
      (fun this_block_height bl ->
        let padding =
          match align with
          | Start -> 0
          | Centre -> (max_height - this_block_height) / 2
          | End -> max_height - this_block_height
        in
        pad_newline padding bl)
      heights blocks
  in
  let padded_blocks_split =
    List.map (String.split_on_char '\n') padded_blocks
  in
  (* This function is more complicated than vcat *)
  List.init max_height (fun i ->
      List.mapi
        (fun j bl_split ->
          let this_block_width = List.nth widths j in
          match List.nth_opt bl_split i with
          | Some line ->
              let line_width = wcswidth line in
              line ^ String.make (this_block_width - line_width) ' '
          | None -> String.make this_block_width ' ')
        padded_blocks_split
      |> String.concat sep)
  |> String.concat "\n"

let box ?(padding : int = 0) (s : string) =
  let text_width = get_width s in
  let box_width = text_width + (2 * padding) in
  let straight_line = String.concat "" (List.init box_width (fun _ -> "─")) in
  let toprule = "┌" ^ straight_line ^ "┐" in
  let lines =
    s |> String.split_on_char '\n'
    |> List.map (fun line ->
           let this_width = wcswidth line in
           let pad = String.make padding ' ' in
           "│" ^ pad ^ line
           ^ String.make (text_width - this_width) ' '
           ^ pad ^ "│")
  in
  let bottomrule = "└" ^ straight_line ^ "┘" in
  toprule ^ "\n" ^ String.concat "\n" lines ^ "\n" ^ bottomrule
