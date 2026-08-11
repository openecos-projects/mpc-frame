# Getting and Using the User Kit

[中文说明](../cn/user-kit.md)

The User Kit is the user-facing `mpc-frame` distribution. It contains FrameTop,
the user design template, required build tools, and user documentation. It does
not contain the reference SoC, internal framework tests, documentation site
sources, or maintainer regression entry points.

## Get the User Kit

Users do not need to clone `main`. After the first maintainer release, clone the
read-only distribution branch directly:

```sh
git clone --branch release/user-kit --single-branch \
  https://github.com/openecos-projects/mpc-frame.git my-frame-design
cd my-frame-design
```

The GitHub Actions run also provides a temporary artifact named
`mpc-frame-user-kit`. Prefer `release/user-kit` for normal development because
artifacts are retained for a limited time.

## Create Your Development Branch

Automation replaces the upstream `release/user-kit` branch. Do not develop
directly on that branch:

```sh
git switch -c user/counter32
```

To push to your own repository:

```sh
git remote rename origin upstream
git remote add origin https://github.com/<user>/<project>.git
git push -u origin user/counter32
```

## Check the Tools

The User Kit requires Python 3, GNU Make, a C++ compiler, and Verilator 5.050:

```sh
make doctor
```

If Verilator 5.050 is not on the default `PATH`:

```sh
make doctor VERILATOR=/path/to/verilator
```

## Develop a Design

```sh
make create NAME=counter32
make check DESIGN=designs/counter32
make trace DESIGN=designs/counter32
make wave DESIGN=designs/counter32
```

The create command generates RTL, `design.json`, a standalone unit test, and a
FrameTop integration test. See the [user design guide](user-guide.md) and
[IO mapping](io-map.md) for the interface and test contracts.

When exactly one unregistered design exists, the shorter form is valid:

```sh
make check
make trace
make wave
```

With multiple unregistered designs, pass `DESIGN=designs/<name>` explicitly.

## Update the User Kit

`release/user-kit` is generated and force-updated. There is currently no
automatic upgrade command. Obtain a clean current kit and copy your design
package into it:

```sh
git clone --branch release/user-kit --single-branch \
  https://github.com/openecos-projects/mpc-frame.git mpc-frame-new
cp -a my-frame-design/designs/counter32 mpc-frame-new/designs/
cd mpc-frame-new
make check DESIGN=designs/counter32
```

Do not force-merge the upstream distribution branch into an existing design
repository.

## Deliver a Design

Users only need to deliver:

```text
designs/<name>/
```

Do not modify `designs/registry.json`, `rtl/generated/FrameDesignRegistry.sv`,
`FrameTop.sv`, or framework RTL. Maintainers assign the permanent design ID.

The distribution branch and development mainline do not currently share commit
history, so a normal PR from a User Kit branch to `main` is not supported.
Submit the complete `designs/<name>/` directory, or provide an archive or patch
according to the project contribution process.

## Clean Generated Output

```sh
make clean
```

This removes generated files under `build/` without deleting design sources.
