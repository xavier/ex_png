# ExPNG

A pure Elixir libary to decode and encode PNG images.

## Limitations

At this point, only true color, 8 bits per channel, non-interlaced images are supported.

```elixir
require ExPNG.Image, as: Image
require ExPNG.Color, as: Color

# Loading a file
png = ExPNG.read("/path/to/image.png")

# => {width, height}
IO.inspect Image.size(png.size)

# Draw some pixels on a transparent canvas and write PNG
ExPNG.image(200, 300)
|> Image.put_pixel(20, 30, Color.rgba(12, 34, 56, 128))
|> Image.put_pixel(50, 50, Color.hex("FF003C"))
|> Image.put_pixel(10, 10, Color.grayscale(133))
|> ExPNG.write("/tmp/test.png")
```

## To Do

- [x] Load TrueColor 8-bit per channel, non-interlaced PNG image data
- [x] Trivial image manipulation primitives
- [x] Support encoding
- [ ] Improve documentation
- [ ] Support Adam7 interlacing
- [ ] Support more color types
- [ ] Image manipulation and compositing functions
- [ ] ...