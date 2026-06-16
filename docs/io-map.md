# IO Map

`mpc-frame` exposes 73 user-configurable pads as one generic bidirectional bus:

```verilog
inout [72:0] user_io
```

Each bit is reserved for shuttle users and has no predefined function in this template. Users may decide the signal direction, protocol, timing, multiplexing, and internal logic according to their own design.

| Signal | Description |
| --- | --- |
| `user_io[0]` | User-defined pad 0 |
| `user_io[1]` | User-defined pad 1 |
| `user_io[2]` | User-defined pad 2 |
| `user_io[3]` | User-defined pad 3 |
| `user_io[4]` | User-defined pad 4 |
| `user_io[5]` | User-defined pad 5 |
| `user_io[6]` | User-defined pad 6 |
| `user_io[7]` | User-defined pad 7 |
| `user_io[8]` | User-defined pad 8 |
| `user_io[9]` | User-defined pad 9 |
| `user_io[10]` | User-defined pad 10 |
| `user_io[11]` | User-defined pad 11 |
| `user_io[12]` | User-defined pad 12 |
| `user_io[13]` | User-defined pad 13 |
| `user_io[14]` | User-defined pad 14 |
| `user_io[15]` | User-defined pad 15 |
| `user_io[16]` | User-defined pad 16 |
| `user_io[17]` | User-defined pad 17 |
| `user_io[18]` | User-defined pad 18 |
| `user_io[19]` | User-defined pad 19 |
| `user_io[20]` | User-defined pad 20 |
| `user_io[21]` | User-defined pad 21 |
| `user_io[22]` | User-defined pad 22 |
| `user_io[23]` | User-defined pad 23 |
| `user_io[24]` | User-defined pad 24 |
| `user_io[25]` | User-defined pad 25 |
| `user_io[26]` | User-defined pad 26 |
| `user_io[27]` | User-defined pad 27 |
| `user_io[28]` | User-defined pad 28 |
| `user_io[29]` | User-defined pad 29 |
| `user_io[30]` | User-defined pad 30 |
| `user_io[31]` | User-defined pad 31 |
| `user_io[32]` | User-defined pad 32 |
| `user_io[33]` | User-defined pad 33 |
| `user_io[34]` | User-defined pad 34 |
| `user_io[35]` | User-defined pad 35 |
| `user_io[36]` | User-defined pad 36 |
| `user_io[37]` | User-defined pad 37 |
| `user_io[38]` | User-defined pad 38 |
| `user_io[39]` | User-defined pad 39 |
| `user_io[40]` | User-defined pad 40 |
| `user_io[41]` | User-defined pad 41 |
| `user_io[42]` | User-defined pad 42 |
| `user_io[43]` | User-defined pad 43 |
| `user_io[44]` | User-defined pad 44 |
| `user_io[45]` | User-defined pad 45 |
| `user_io[46]` | User-defined pad 46 |
| `user_io[47]` | User-defined pad 47 |
| `user_io[48]` | User-defined pad 48 |
| `user_io[49]` | User-defined pad 49 |
| `user_io[50]` | User-defined pad 50 |
| `user_io[51]` | User-defined pad 51 |
| `user_io[52]` | User-defined pad 52 |
| `user_io[53]` | User-defined pad 53 |
| `user_io[54]` | User-defined pad 54 |
| `user_io[55]` | User-defined pad 55 |
| `user_io[56]` | User-defined pad 56 |
| `user_io[57]` | User-defined pad 57 |
| `user_io[58]` | User-defined pad 58 |
| `user_io[59]` | User-defined pad 59 |
| `user_io[60]` | User-defined pad 60 |
| `user_io[61]` | User-defined pad 61 |
| `user_io[62]` | User-defined pad 62 |
| `user_io[63]` | User-defined pad 63 |
| `user_io[64]` | User-defined pad 64 |
| `user_io[65]` | User-defined pad 65 |
| `user_io[66]` | User-defined pad 66 |
| `user_io[67]` | User-defined pad 67 |
| `user_io[68]` | User-defined pad 68 |
| `user_io[69]` | User-defined pad 69 |
| `user_io[70]` | User-defined pad 70 |
| `user_io[71]` | User-defined pad 71 |
| `user_io[72]` | User-defined pad 72 |
