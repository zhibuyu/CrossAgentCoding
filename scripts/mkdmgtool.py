#!/usr/bin/env python3
"""Safe DMG creator.

A valid macOS UDZO ``.dmg`` is a *compressed disk image*: a full HFS+/APFS
filesystem split into zlib-compressed chunks, described by a ``mish`` BLKX
block table plus checksums in the resource-fork plist. It cannot be fabricated
by simply ``zlib``-compressing a ``tar`` of a folder -- doing that yields a file
macOS rejects with "磁盘映像已损坏 / disk image is corrupted".

So this tool only ever produces a *real* DMG, by delegating to the system
``hdiutil``. If ``hdiutil`` is unavailable (i.e. not running on macOS) it fails
loudly with a clear message instead of writing a broken disk image.
"""
import os, shutil, subprocess, sys


def create_udzo_dmg(src_folder, output_path, volume_name):
    """Create a valid UDZO (zlib-compressed) DMG from a source folder."""
    hdiutil = shutil.which("hdiutil")
    if not hdiutil:
        raise RuntimeError(
            "hdiutil not found: a valid .dmg can only be created on macOS. "
            "Run scripts/build-macos.sh on a Mac instead. "
            "Refusing to write an invalid disk image."
        )

    # -ov: overwrite existing; -format UDZO: zlib-compressed read-only image.
    subprocess.run(
        [
            hdiutil, "create",
            "-volname", volume_name,
            "-srcfolder", src_folder,
            "-ov", "-format", "UDZO",
            output_path,
        ],
        check=True,
    )
    return True


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <src_folder> <output.dmg> <volume_name>")
        sys.exit(1)

    src = sys.argv[1]
    out = sys.argv[2]
    name = sys.argv[3]

    if not os.path.isdir(src):
        print(f"ERROR: {src} is not a directory", file=sys.stderr)
        sys.exit(1)

    try:
        create_udzo_dmg(src, out, name)
    except (RuntimeError, subprocess.CalledProcessError) as e:
        print(f"ERROR: failed to create DMG: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Created: {out} ({os.path.getsize(out)} bytes)")
