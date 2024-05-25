
; Simple text editor - fasm example program
; Made by imperial from fasm's MiniPad Example using windows API
format PE GUI 4.0
entry start

;include 'win32a.inc'
include 'win32ax.inc'


IDR_ICON = 17
IDR_MENU = 37

IDM_NEW   = 101
IDM_EXIT  = 102
IDM_OPEN  = 200
IDM_SAVE  = 201
IDM_ABOUT = 901

section '.text' code readable executable

  start:

        invoke  GetModuleHandle,0
        mov     [wc.hInstance],eax

        invoke  LoadIcon,eax,IDR_ICON
        mov     [wc.hIcon],eax
        invoke  LoadCursor,0,IDC_ARROW
        mov     [wc.hCursor],eax
        invoke  RegisterClass,wc
        test    eax,eax
        jz      error

        invoke  LoadMenu,[wc.hInstance],IDR_MENU
        invoke  CreateWindowEx,0,_class,_title,WS_VISIBLE+WS_OVERLAPPEDWINDOW,144,128,256,256,NULL,eax,[wc.hInstance],NULL
        test    eax,eax
        jz      error

  msg_loop:
        invoke  GetMessage,msg,NULL,0,0
        cmp     eax,1
        jb      end_loop
        jne     msg_loop
        invoke  TranslateMessage,msg
        invoke  DispatchMessage,msg
        jmp     msg_loop

  error:
        invoke  MessageBox,NULL,_error,NULL,MB_ICONERROR+MB_OK

  end_loop:
        invoke  ExitProcess,[msg.wParam]

proc WindowProc hwnd,wmsg,wparam,lparam
        push    ebx esi edi
        mov     eax,[wmsg]
        cmp     eax,WM_CREATE
        je      .wmcreate
        cmp     eax,WM_SIZE
        je      .wmsize
        cmp     eax,WM_SETFOCUS
        je      .wmsetfocus
        cmp     eax,WM_COMMAND
        je      .wmcommand
        cmp     eax,WM_DESTROY
        je      .wmdestroy
  .defwndproc:
        invoke  DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
        jmp     .finish
  .wmcreate:
        invoke  GetClientRect,[hwnd],client
        invoke  CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+WS_HSCROLL+WS_VSCROLL+ES_AUTOHSCROLL+ES_AUTOVSCROLL+ES_MULTILINE,[client.left],[client.top],[client.right],[client.bottom],[hwnd],0,[wc.hInstance],NULL
        or      eax,eax
        jz      .failed
        mov     [edithwnd],eax
        invoke  CreateFont,16,0,0,0,0,FALSE,FALSE,FALSE,ANSI_CHARSET,OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,FIXED_PITCH+FF_DONTCARE,NULL
        or      eax,eax
        jz      .failed
        mov     [editfont],eax
        invoke  SendMessage,[edithwnd],WM_SETFONT,eax,FALSE
        xor     eax,eax
        jmp     .finish
      .failed:
        or      eax,-1
        jmp     .finish
  .wmsize:
        invoke  GetClientRect,[hwnd],client
        invoke  MoveWindow,[edithwnd],[client.left],[client.top],[client.right],[client.bottom],TRUE
        xor     eax,eax
        jmp     .finish
  .wmsetfocus:
        invoke  SetFocus,[edithwnd]
        xor     eax,eax
        jmp     .finish
  .wmcommand:
        mov     eax,[wparam]
        and     eax,0FFFFh
        cmp     eax,IDM_NEW
        je      .new
        cmp     eax,IDM_ABOUT
        je      .about
        cmp     eax,IDM_EXIT
        je      .wmdestroy
        cmp     eax,IDM_SAVE
        je      .savedialog
        cmp     eax,IDM_OPEN
        je     .opendialog
        jmp     .defwndproc ;designate the end of this section
      .new:
        invoke  SendMessage,[edithwnd],WM_SETTEXT,0,0
        jmp     .finish
      .about:
        invoke  MessageBox,[hwnd],_about_text,_about_title,MB_OK
        jmp     .finish
      .opendialog:
        mov     [ofn.lStructSize],sizeof.OPENFILENAME
        invoke  GetModuleHandle,0
        mov     [ofn.hInstance],eax
        mov     [ofn.hwndOwner],HWND_DESKTOP
        mov     [ofn.lpstrInitialDir],NULL
        mov     [ofn.lpstrCustomFilter],NULL
        mov     [ofn.nFilterIndex],1
        mov     [ofn.lpstrFileTitle],name_buffer
        mov     [ofn.nMaxFileTitle],NAME_MAX
        mov     [ofn.lpstrFile],path_buffer
        mov     [ofn.nMaxFile],PATH_MAX
        mov     [path_buffer],0
        mov     [ofn.lpstrFilter],asm_filter
        mov     [ofn.lpstrDefExt],asm_extension
        mov     [ofn.Flags],OFN_EXPLORER+OFN_FILEMUSTEXIST
        mov     [ofn.lpstrTitle],NULL
        invoke  GetOpenFileName,ofn
        .if eax

                invoke CreateFileA,path_buffer,GENERIC_READ,0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
                mov [hFile], eax
                invoke  GetFileSize, [hFile], 0
                mov [nSize], eax
               ; invoke  MessageBox,HWND_DESKTOP,path_buffer,name_buffer,MB_OK
                ;invoke ReadFile,ofn,bfr,10

                invoke  ReadFile, [hFile], lpBuffer, [nSize], lpBytesRead, 0

                mov [result_of_reading],eax
                ;mov [msg],lpBuffer
                invoke  MessageBox,HWND_DESKTOP,lpBuffer,name_buffer,MB_OK
                invoke  SendMessage,[edithwnd],WM_SETTEXT,0,lpBuffer
                invoke CloseHandle, [hFile]
        .endif
        jmp     .finish
  .savedialog:
        ;invoke PeekMessageA,get_text_content,[edithwnd],WM_SETTEXT,WM_KEYLAST
        ;invoke  SendMessage,[edithwnd],WM_GETTEXT,0,get_text_content
        mov     [ofn.lStructSize],sizeof.OPENFILENAME
        invoke  GetModuleHandle,0
        mov     [ofn.hInstance],eax
        mov     [ofn.hwndOwner],HWND_DESKTOP
        mov     [ofn.lpstrInitialDir],NULL
        mov     [ofn.lpstrCustomFilter],NULL
        mov     [ofn.nFilterIndex],1
        mov     [ofn.lpstrFileTitle],name_buffer
        mov     [ofn.nMaxFileTitle],NAME_MAX
        mov     [ofn.lpstrFile],path_buffer
        mov     [ofn.nMaxFile],PATH_MAX
        mov     [path_buffer],0
        mov     [ofn.lpstrFilter],asm_filter
        mov     [ofn.lpstrDefExt],asm_extension
        mov     [ofn.Flags],OFN_EXPLORER+OFN_FILEMUSTEXIST
        mov     [ofn.lpstrTitle],NULL
        invoke  GetSaveFileNameA,ofn
        .if eax
            invoke  MessageBox,HWND_DESKTOP,path_buffer,"ty",MB_OK
            invoke CreateFileA,path_buffer,GENERIC_READ+GENERIC_WRITE,0, 0, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0
            ; invoke  MessageBox,HWND_DESKTOP,path_buffer,name_buffer,MB_OK
            ;invoke ReadFile,ofn,bfr,10
            mov [hFileWrite],eax
            invoke  SendMessage,[edithwnd],WM_GETTEXT,variable_buffer_size,get_text_content
            mov [result_of_writing],eax
            invoke  WriteFile, [hFileWrite], result_of_writing,1000 , lpBytesWrite, 0

            mov [result_of_reading],eax
            ;mov [msg],lpBuffer
            invoke  MessageBox,HWND_DESKTOP,lpBuffer,name_buffer,MB_OK
            invoke CloseHandle, [hFileWrite]
        .endif
        ;invoke  SendMessage,[edithwnd],WM_GETTEXT,variable_buffer_size,get_text_content

        jmp .finish
  .wmdestroy:
        invoke  DeleteObject,[editfont]
        invoke  PostQuitMessage,0
        xor     eax,eax
  .finish:
        pop     edi esi ebx
        ret
endp

section '.data' data readable writeable
  NAME_MAX = 100h
  PATH_MAX = 1000h

  asm_filter db 'Text Files',0,'*.TXT;*.text;*.ASH',0
             db 'All files',0,'*.*',0
             db 0

  asm_extension db '.txt',0
  bfr dd ?
  hFile dd ?
  hFileWrite dd ?
  nSize dd 1000
  result_of_reading dd ?
  result_of_writing dd ?
  get_text_content dd ?
  lpBytesRead dd ?
  lpBuffer rb 8192
  lpBytesWrite dd ?
  variable_buffer_size dd ?
  ofn OPENFILENAME

  name_buffer rb NAME_MAX
  path_buffer rb PATH_MAX

  _title TCHAR 'EdiText',0
  _about_title TCHAR 'About MiniPad',0
  _about_text TCHAR 'Made by Impérial from flat assembler example',0
  _error TCHAR 'Startup failed.',0

  _class TCHAR 'MINIPAD32',0
  _edit TCHAR 'EDIT',0

  wc WNDCLASS 0,WindowProc,0,0,NULL,NULL,NULL,COLOR_BTNFACE+1,NULL,_class

  edithwnd dd ?
  editfont dd ?

  msg MSG
  client RECT

section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
          user,'USER32.DLL',\
          gdi,'GDI32.DLL',\
          commdlg,'COMDLG32.DLL'

  import kernel,\
         GetModuleHandle,'GetModuleHandleA',\
         ReadFile,'ReadFile',\
         WriteFile,'WriteFile',\
         CreateFileA,'CreateFileA',\
         GetFileSize,'GetFileSize',\
         CloseHandle,'CloseHandle',\
         ExitProcess,'ExitProcess'

  import user,\
         RegisterClass,'RegisterClassA',\
         CreateWindowEx,'CreateWindowExA',\
         PeekMessageA,'PeekMessageA',\
         DefWindowProc,'DefWindowProcA',\
         SetWindowLong,'SetWindowLongA',\
         RedrawWindow,'RedrawWindow',\
         GetMessage,'GetMessageA',\
         TranslateMessage,'TranslateMessage',\
         DispatchMessage,'DispatchMessageA',\
         SendMessage,'SendMessageA',\
         LoadCursor,'LoadCursorA',\
         LoadIcon,'LoadIconA',\
         LoadMenu,'LoadMenuA',\
         GetClientRect,'GetClientRect',\
         MoveWindow,'MoveWindow',\
         SetFocus,'SetFocus',\
         MessageBox,'MessageBoxA',\
         GetMessageA,'GetMessageA',\
         PostQuitMessage,'PostQuitMessage'

  import gdi,\
         CreateFont,'CreateFontA',\
         DeleteObject,'DeleteObject'

  import commdlg,\
         GetSaveFileNameA,'GetSaveFileNameA',\
         GetOpenFileName,'GetOpenFileNameA'
section '.rsrc' resource data readable

  ; resource directory

  directory RT_MENU,menus,\
            RT_ICON,icons,\
            RT_GROUP_ICON,group_icons,\
            RT_VERSION,versions

  ; resource subdirectories

  resource menus,\
           IDR_MENU,LANG_ENGLISH+SUBLANG_DEFAULT,main_menu

  resource icons,\
           1,LANG_NEUTRAL,icon_data

  resource group_icons,\
           IDR_ICON,LANG_NEUTRAL,main_icon

  resource versions,\
           1,LANG_NEUTRAL,version

  menu main_menu
       menuitem '&File',0,MFR_POPUP
                menuitem '&New',IDM_NEW
                menuitem '&Open',IDM_OPEN
                menuitem '&Save',IDM_SAVE
                menuseparator
                menuitem 'E&xit',IDM_EXIT,MFR_END



       menuitem '&Help',0,MFR_POPUP + MFR_END
                menuitem '&About...',IDM_ABOUT,MFR_END

  icon main_icon,icon_data,'minipad.ico'

  versioninfo version,VOS__WINDOWS32,VFT_APP,VFT2_UNKNOWN,LANG_ENGLISH+SUBLANG_DEFAULT,0,\
              'FileDescription','MiniPad - example program',\
              'LegalCopyright','No rights reserved.',\
              'FileVersion','1.0',\
              'ProductVersion','1.0',\
              'OriginalFilename','MINIPAD.EXE'
