; ISO 9660 image with an El Torito 1.44 MB floppy-emulation boot entry.
; Built with NASM so the Windows build needs no external ISO mastering tool.
bits 16
%define BLOCK 2048
%define PVD_LBA 16
%define BOOT_RECORD_LBA 17
%define TERMINATOR_LBA 18
%define PATH_L_LBA 19
%define PATH_M_LBA 20
%define ROOT_LBA 21
%define CATALOG_LBA 22
%define FLOPPY_LBA 23
%define FLOPPY_SIZE 1474560
%define VOLUME_BLOCKS (FLOPPY_LBA + FLOPPY_SIZE / BLOCK)

%macro both16 1
    dw %1
    db ((%1) >> 8) & 0xff, (%1) & 0xff
%endmacro
%macro both32 1
    dd %1
    db ((%1) >> 24) & 0xff, ((%1) >> 16) & 0xff, ((%1) >> 8) & 0xff, (%1) & 0xff
%endmacro
%macro pad_block 1
    times ((%1) * BLOCK) - ($ - $$) db 0
%endmacro
; Seven-byte ISO directory timestamp: 2026-01-01 00:00:00 UTC.
%macro timestamp 0
    db 126, 1, 1, 0, 0, 0, 0
%endmacro
%macro root_record 1
    db 34, 0
    both32 ROOT_LBA
    both32 BLOCK
    timestamp
    db 2, 0, 0
    both16 1
    db 1, %1
%endmacro

; System area: reserved by ISO 9660.
times PVD_LBA * BLOCK db 0

; Primary volume descriptor.
db 1, 'CD001', 1, 0
db 'GAME.ISO', 24 dup(' ')
db 'GAME_ISO', 24 dup(' ')
times 8 db 0
both32 VOLUME_BLOCKS
times 32 db 0
both16 1
both16 1
both16 BLOCK
both32 10                    ; root-only path table size
dd PATH_L_LBA, 0
db 0, 0, 0, PATH_M_LBA      ; big-endian type-M path table location
dd 0
root_record 0
times 128*4 db ' '
times 37*3 db ' '
%rep 4                       ; unspecified volume dates, UTC offset zero
    times 16 db '0'
    db 0
%endrep
db 1, 0                      ; file structure version, reserved
times 512 db 0               ; application use
pad_block BOOT_RECORD_LBA

; El Torito boot record volume descriptor.
db 0, 'CD001', 1
db 'EL TORITO SPECIFICATION'
times 32-($-$$-(BOOT_RECORD_LBA*BLOCK+7)) db 0
times 32 db 0
dd CATALOG_LBA
pad_block TERMINATOR_LBA

db 255, 'CD001', 1
pad_block PATH_L_LBA

; Type-L and type-M root path tables.
db 1, 0
dd ROOT_LBA
dw 1
db 0, 0
pad_block PATH_M_LBA
db 1, 0
db 0, 0, 0, ROOT_LBA
db 0, 1
db 0, 0
pad_block ROOT_LBA

; Root directory with the embedded floppy image available as GAME.IMG.
root_record 0
root_record 1
db 44, 0
both32 FLOPPY_LBA
both32 FLOPPY_SIZE
timestamp
db 0, 0, 0
both16 1
db 10, 'GAME.IMG;1', 0
pad_block CATALOG_LBA

; Validation entry: the 16 little-endian words sum to zero.
db 1, 0
dw 0
times 24 db 0
dw 0x55aa
dw 0xaa55
; Bootable, 1.44 MB floppy emulation, default segment, one initial 512-byte sector.
db 0x88, 2
dw 0
db 0, 0
dw 1
dd FLOPPY_LBA
times 20 db 0
pad_block FLOPPY_LBA

incbin 'game.img'
%if ($-$$) != VOLUME_BLOCKS * BLOCK
    %error game.img must be exactly 1.44 MB
%endif
