bits 16
incbin 'boot.bin'
%if ($-$$) != 512
    %error boot sector must be 512 bytes
%endif
incbin 'stage2.bin'
%if ($-$$) != 1024
    %error stage2 must be 512 bytes
%endif
incbin 'main.bin'
%if ($-$$) > (1024 + 64*512)
    %error main image exceeds loader capacity
%endif
times 1474560-($-$$) db 0
