# ExPNG

A pure Elixir libary to decode and encode PNG images.

## Usage

```elixir
require ExPNG.Image, as: Image
require ExPNG.Color, as: Color

# Loading a file
png = ExPNG.read("/path/to/image.png")

# => {width, height}
IO.inspect Image.size(png)

# Draw some pixels on a transparent canvas and write PNG
ExPNG.image(200, 300)
|> Image.set_pixel(20, 30, Color.rgba(12, 34, 56, 128))
|> Image.set_pixel(50, 50, Color.hex("FF003C"))
|> Image.set_pixel(10, 10, Color.grayscale(133))
|> ExPNG.write("/tmp/test.png")
```

## Current Limitations

At this point, only true color, 8 bits per channel, non-interlaced images are supported.

## To Do

- [x] Load TrueColor 8-bit per channel, non-interlaced PNG image data
- [x] Trivial image manipulation primitives
- [x] Support encoding
- [x] Refactoring (extract some functions in submodules, ...)
- [ ] API revision (tension between ExPNG.fun and Image.fun...)
- [ ] Improve documentation
- [ ] Hex package
- [ ] Support Adam7 interlacing
- [ ] Support more color types
- [ ] Image manipulation and compositing functions
- [ ] ...


## License

   Copyright 2014 Xavier Defrang

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

## Additional Credits

Some test images were taken from Willem van Schaik's [PNG Suite](http://www.schaik.com/pngsuite/)
