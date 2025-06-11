open Patchlings.Graphics

   let%expect_test "how to do a test" =
     check_output ();
     [%expect {| <ESC>_Gf=24,s=10,v=20;<payload><ESC> |}]
