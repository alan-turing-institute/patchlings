import term_image
import term_image.image
# import term_image.image

# from term_image.image import from_file

fpath = "../player_unique_tiles.png"

image = term_image.image.from_file(fpath)
my_str = f"{image:>._#.5}"

if __name__ == "__main__":
    # print(str(my_str))
    image.draw()
