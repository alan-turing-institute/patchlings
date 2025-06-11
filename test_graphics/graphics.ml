[@@@warnerror "-unused-value-declaration"]
open Graphics
(* open Base64 *)

let build_graphic size =
  (* Start with a square, size `size x size` all zeros *)
  (* let base = Array.make_matrix size size blue in *)
  let base = Array.make_matrix size size blue in
  (* let base = Array.make_matrix size size 256*256*256*128 in *)

  (* Fill the square with a gradient from blue to red *)
  (* for i = 0 to size - 1 do
    for j = 0 to size - 1 do
      let _red = (i * 255) / (size - 1) in
      let _blue = (j * 255) / (size - 1) in
      base.(i).(j) <- (rgb 255 0 255)
    done
  done; *)
  base
(*
let debug_image dmp =
  (* let dmp = build_graphic 5 in *)
  (* let dmp = dump_image img in *)
  Array.iter
    (fun row ->
      Array.iter
        (fun pxl ->
          match pxl with
          | color ->
              Printf.printf "Pixel at with color %d\n" color
          ) row
    ) dmp *)

(* let bytes_from_image img =
  Array.iter
    (fun row ->
      Array.iter
        (fun pxl ->
        match pxl with
        | color -> *)


(* let play_with_bytes () =
  let p1 : int = 0x1 in
  let p2 : int = 256 + 2 in
  let p3 : int = (256*256) + 4 in
  let p4 : int = (256*256*256) + 8 in
  (* let p5 : int = (256*256*256) + 16 in *)
  let sum = p1 + p2 + p3 + p4 in
  let msg = "\np1=" ^ (string_of_int p1) ^ "\np2=" ^ (string_of_int p2) ^ "\np3=" ^ (string_of_int p3) ^ "\np4=" ^ (string_of_int p4) ^ "\nsum=" ^ (string_of_int sum) ^ "\n" in
  print_string msg;
  (* sum *)

  Int64.of_string "H" 
   *)


let int_to_bytes int_in =
  let int_32 = Int32.of_int int_in in
  (* let int_64 = int_in in *)
  let new_bytes = Bytes.create 4 in
  (* Set the bytes in little-endian order *)
  (* Bytes.set_int8 new_bytes 0 (int_in land 0xFF); *)
  Bytes.set_int32_ne new_bytes 0 int_32;
  let new_str = String.of_bytes new_bytes in
  print_string ("int_in: >" ^ string_of_int int_in ^ "< \n");
  print_string ("int_to_bytes: >" ^ new_str ^ "< \n");
  print_string ("length of: >" ^ string_of_int (String.length new_str) ^ "< \n");
  new_bytes
  (* new_str *)

let img_to_bytes img =
  (* Convert the image to a string representation of bytes *)
  let width = Array.length img in
  let height = Array.length img.(0) in
  let new_bytes = Bytes.create (width * height * 4) in
  Array.iteri
    (fun i row ->
      Array.iteri
        (fun j pxl ->
          let index = (i * height + j) * 4 in
          let src = int_to_bytes pxl in
          Bytes.blit src 0 new_bytes index 3
        ) row
    ) img;
  new_bytes


let () =
  open_graph "";
  let _ = print_string "\nStarting test output\n" in
  let size = 10 in
  let base_array = build_graphic size in
  let _base_bytes = img_to_bytes base_array in
  
  print_string "\n";
  let _str_img = String.of_bytes _base_bytes in

  (* let local_path = "/Users/a.smith/code/hackweek2025/patchlings/test_bitmap.bmp" in *)
  let local_path = "/Users/a.smith/code/hackweek2025/patchlings/player_unique_tiles.png" in
  let ic = open_in local_path in
  let size = in_channel_length ic in
  let byte_img = Bytes.create size in
  really_input ic byte_img 0 size;
  close_in ic;

  let str_img = Bytes.to_string byte_img in

  (* print_string ("int_to_bytes: >" ^ byte_img ^ "< \n"); *)
  print_string ("length of: >" ^ string_of_int (String.length str_img) ^ "< \n");

  let enc = Base64.encode_string (str_img) in
  (* print_string ("Base64 encoded image: >" ^ enc ^ "< \n"); *)
  (* print_string ("\x1B_Gf=32,s=" ^ string_of_int size ^ ",v=" ^ string_of_int size ^ ";" ^ enc ^ "\x1B\\"); *)
  
  print_string "\027]1337;File=inline=1;width=50%%;height=50%%;preserveAspectRatio=0:";
  print_string enc;
  print_string "\027\\";
(*   
  print_string ("\027_Gf=100,t=f;" ^ Base64.encode_string local_path ^ "\027\\"); *)
  print_string "\nEnd test output\n";
