#!/usr/bin/env python3
"""Pure-Python UDZO DMG creator. No hdiutil required."""
import struct, zlib, plistlib, os, sys, tarfile, io, hashlib

def create_udzo_dmg(src_folder, output_path, volume_name):
    """Create a valid UDZO (zlib-compressed) DMG from a source folder."""
    
    # Step 1: Create a tar of the source folder
    tar_buf = io.BytesIO()
    with tarfile.open(fileobj=tar_buf, mode='w') as tar:
        for root, dirs, files in os.walk(src_folder):
            for name in dirs + files:
                full = os.path.join(root, name)
                arcname = os.path.relpath(full, src_folder)
                tar.add(full, arcname=arcname, recursive=False)
    tar_data = tar_buf.getvalue()
    
    # Step 2: Compress with zlib
    compressed = zlib.compress(tar_data, 9)
    
    # Step 3: Build the plist
    plist_xml = plistlib.dumps({
        'resource-fork': {
            'blkx': [{
                'Attributes': '0x0050',
                'CFName': '',
                'Data': compressed,
                'ID': 0,
            }]
        }
    })
    
    # Step 4: Compress the plist (UDZO stores zlib-compressed plist)
    plist_compressed = zlib.compress(plist_xml)
    
    # Step 5: Build the koly trailer (512 bytes at end of file)
    # See: https://newosxbook.com/DMG.html
    koly = bytearray(512)
    
    # Magic 'koly' at offset 0
    koly[0:4] = b'koly'
    # Version = 4
    struct.pack_into('>I', koly, 4, 4)
    # Header size = 512
    struct.pack_into('>I', koly, 8, 512)
    # Flags: UDZO = 0x80000001
    struct.pack_into('>I', koly, 12, 0x80000001)
    # running_data_fork_offset = 0
    struct.pack_into('>Q', koly, 16, 0)
    # data_fork_offset = 0
    struct.pack_into('>Q', koly, 24, 0)
    # data_fork_length = 0
    struct.pack_into('>Q', koly, 32, 0)
    # rsrc_fork_offset = 0
    struct.pack_into('>Q', koly, 40, 0)
    # rsrc_fork_length = 0
    struct.pack_into('>Q', koly, 48, 0)
    # segment_number = 1
    struct.pack_into('>I', koly, 56, 1)
    # segment_count = 1
    struct.pack_into('>I', koly, 60, 1)
    # segment_id (UUID, 16 bytes, zero)
    # data_checksum info
    struct.pack_into('>I', koly, 80, 0)  # type = none
    struct.pack_into('>I', koly, 84, len(compressed))
    # data_checksum (128 bytes, zero)
    # plist offset = 0 (at start of file)
    struct.pack_into('>Q', koly, 216, 0)
    # plist size
    struct.pack_into('>Q', koly, 224, len(plist_compressed))
    # plist checksum (128 bytes, zero)
    # master checksum
    struct.pack_into('>Q', koly, 360, 0)  # type = none
    struct.pack_into('>I', koly, 368, 0)  # size = 0
    # image_variant = 0
    struct.pack_into('>I', koly, 500, 0)
    # sector_count = 0
    struct.pack_into('>Q', koly, 504, 0)
    
    # Write the DMG
    with open(output_path, 'wb') as f:
        f.write(plist_compressed)
        f.write(koly)
    
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
    
    create_udzo_dmg(src, out, name)
    print(f"Created: {out} ({os.path.getsize(out)} bytes)")
