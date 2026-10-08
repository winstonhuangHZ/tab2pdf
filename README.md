# Tab2PDF

A small macOS front end that turns a Guitar Pro file into an engraved PDF with
standard notation and tablature side by side.

It is a graphical wrapper around [TuxGuitar](https://github.com/helge17/tuxguitar)'s
LilyPond exporter, so nothing here reimplements file parsing or music engraving:

```
.gp3 / .gp4 / .gp5 / .gpx / .mid
        |
        v
   gp2pdf.jar        reads the file, writes LilyPond source
        |
        v
   LilyPond          engraves it
        |
        v
       PDF
```

## Requirements

- **macOS 13** or newer.
- **Java** — a JDK or JRE, any recent version. The app looks in
  `/usr/libexec/java_home`, then `/usr/local/bin`, `/opt/homebrew/bin`, `/usr/bin`.
- **LilyPond** — not bundled, because it is a large native toolchain. Install it
  from [lilypond.org](https://lilypond.org/download.html), or grab the standalone
  macOS build and unpack it somewhere. The app searches
  `~/tools/lilypond-2.26.0/bin/lilypond`, `/Applications/LilyPond.app/...`,
  `/usr/local/bin`, `/opt/homebrew/bin`, and honours a `LILYPOND` environment
  variable. If it is somewhere else, paste the path into the **LilyPond** field.

The field is remembered between launches.

## Build

```sh
swift build -c release
Scripts/make-app.sh          # produces build/Tab2PDF.app
```

`swift run` works too if you just want to try it, but a real `.app` behaves
better as a windowed application.

## Options

| Option | Values | Effect |
|---|---|---|
| Style | Modern (Computer Modern), Modern (sans serif), LilyPond default | Text face and title markup. The default is the lightweight Computer Modern look, not LilyPond's stock bold Century Schoolbook. |
| Spacing | Airy, Compact, LilyPond default | Only page spacing. A strummed beat prints as a stack of note heads plus six fret numbers, so the stock spacing reads as cramped. |
| Track | `0` for every track, or a 1-based track number | Guitar Pro files hold several tracks and they are engraved separately. |

Chord diagrams, hammer and pull slurs, bends, let ring and drum notation are
produced by the exporter itself and need no options.

## About gp2pdf.jar

The jar is built from a fork of TuxGuitar whose LilyPond exporter was extended
with the style, spacing, chord name and percussion work this app exposes. It is
checked in so the app builds without a Java toolchain.

TuxGuitar is LGPL, and so is this jar.
