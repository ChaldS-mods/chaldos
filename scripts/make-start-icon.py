"""Generate ChaldOS start menu icon (24x24 pixel art PNG)"""
from PIL import Image

img = Image.new('RGBA', (24, 24), (0, 0, 0, 0))
pixels = img.load()

# ChaldOS "C" logo — cyan/blue pixel art
# Colors
CYAN    = (0, 200, 220, 255)
BLUE    = (30, 60, 140, 255)
WHITE   = (200, 220, 255, 255)
DARK    = (10, 20, 50, 255)

# Draw rounded square background
for y in range(24):
    for x in range(24):
        # Outer rounded square
        if 2 <= y <= 21 and 2 <= x <= 21:
            # Inner gradient
            t = (x + y) / 48.0
            r = int(10 + t * 20)
            g = int(60 + t * 140)
            b = int(140 + t * 80)
            pixels[x, y] = (r, g, b, 255)

# Draw stylized "C" shape
for y in range(24):
    for x in range(24):
        # Outer ring of C: top, left, bottom
        if (x == 5 and 5 <= y <= 18) or \
           (y == 5 and 7 <= x <= 18) or \
           (y == 18 and 7 <= x <= 18):
            pixels[x, y] = CYAN

# Inner highlight on top-left
for y in range(24):
    for x in range(24):
        if (x == 6 and 6 <= y <= 11) or \
           (y == 6 and 6 <= x <= 10):
            r, g, b, a = pixels[x, y]
            pixels[x, y] = (min(r + 60, 255), min(g + 60, 255), min(b + 60, 255), 255)

# Bright pixel accent
pixels[4, 9] = WHITE

img.save('rootfs/usr/share/weston/chaldos-start.png')
print("Icon created: rootfs/usr/share/weston/chaldos-start.png")
