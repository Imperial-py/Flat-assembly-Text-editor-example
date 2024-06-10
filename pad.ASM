
; Simple text editor - fasm example program
; Made by imperial from fasm's MiniPad Example using windows API
format PE GUI 4.0
entry start

;include 'win32a.inc'
include 'win32ax.inc'
include 'ENCODING\utf8.inc'

IDR_ICON = 17
IDR_MENU = 37

IDM_NEW   = 101
IDM_EXIT  = 102
IDM_OPEN  = 200
IDM_SAVE  = 201
IDM_COLOR = 300
IDM_FONT  = 301
IDM_ABOUT = 901


IDM_SCROLL_BAR_COLOR = 1000
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
proc sub_edit_proc hedit,umsg,wparam,lparam
     ;invoke MessageBox,HWND_DESKTOP,'result' ,'returned a non null value' ,MB_OK
      cmp     [umsg],WM_CTLCOLORSCROLLBAR
      je      .para_scrollbar_color
      invoke InitializeFlatSB ,[hedit]
      invoke FlatSB_SetScrollProp,[hedit],0x128,brush_clref,TRUE
      .if eax
       invoke MessageBox,HWND_DESKTOP,'result' ,'returned a non null value' ,MB_OK
      .endif
      ; all other ones forwared to original WindowProc:
      invoke  CallWindowProc,[_def_edit_proc],[hedit],[umsg],[wparam],[lparam]
      jmp     .finished
      .para_scrollbar_color:
        invoke MessageBox,HWND_DESKTOP,'result' ,'returned a non null value' ,MB_OK
        invoke CreateSolidBrush,[brush_clref]
        invoke MessageBox,HWND_DESKTOP,'result' ,'returned a non null value' ,MB_OK
        .if eax
        invoke MessageBox,HWND_DESKTOP,'result' ,'returned a non null value' ,MB_OK
        .endif
        mov [brush_handle],eax
        invoke SelectObject,[wparam],[brush_handle]
        invoke DeleteObject,[brush_handle]
        jmp .finished
      .finished:
        pop     edi esi ebx
        ret

endp
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
        cmp     [wmsg],WM_CTLCOLOREDIT
        je      .editcolor
  .defwndproc:
        invoke  DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
        jmp     .finish
  .wmcreate:
        invoke  GetClientRect,[hwnd],client
        invoke  CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+WS_HSCROLL+WS_VSCROLL+ES_AUTOHSCROLL+ES_AUTOVSCROLL+ES_MULTILINE,[client.left],[client.top],[client.right],[client.bottom],[hwnd],0,[wc.hInstance],NULL
        or      eax,eax
        jz      .failed
        mov     [edithwnd],eax
        invoke  CreateFont,16,0,0,0,800,FALSE,FALSE,FALSE,ANSI_CHARSET,OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,DEFAULT_PITCH+FF_ROMAN,NULL      ; invoke  CreateFont,16,0,0,0,0,FALSE,FALSE,FALSE,ANSI_CHARSET,OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,FIXED_PITCH+FF_DONTCARE,NULL
        or      eax,eax
        jz      .failed
        mov     [editfont],eax
        invoke  SendMessage,[edithwnd],WM_SETFONT,eax,FALSE
        xor     eax,eax
        ;;;;;;;;;;;;;
        ;-----------------
        ;;;;;;;;;;;;;
        push    sub_edit_proc
        push    GWL_WNDPROC
        push    eax
        invoke  GetWindowLong,eax,GWL_WNDPROC
        mov     [_def_edit_proc],eax
        call    [SetWindowLong]
        invoke  SetWindowLong,[hwnd],GWL_WNDPROC,sub_edit_proc
        mov     [_def_edit_proc],eax

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
        cmp     eax,IDM_COLOR
        je     .apply_color
        cmp     eax,IDM_FONT
        je     .apply_font
        cmp     eax,IDM_SCROLL_BAR_COLOR
        je     .set_scrollbar_color
        cmp     [wparam],WM_CTLCOLORSCROLLBAR
        je      .param_scrollbar_color
        jmp     .defwndproc ;designate the end of this section
      .editcolor:
        ;invoke  MessageBox,HWND_DESKTOP,clr ,clr ,MB_OK
        invoke  SetTextColor, [wparam], [clr];0x000000FF
        jmp .finish
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
  .set_scrollbar_color:
        mov [cclr.lpCustColors],cclr.lpCustColors
        mov [cclr.lStructSize],9*4
        mov [cclr.Flags],$2
        mov [cclr.hwndOwner],$0
        mov [cclr.hInstance],$0
        mov [cclr.rgbResult],$0
        mov [cclr.lCustData],$0
        mov [cclr.lpTemplateName],$0
        invoke ChooseColor,cclr
        mov eax, [cclr.rgbResult]
        mov [brush_clref], eax
        jmp .finish
  .param_scrollbar_color:
        invoke MessageBox,HWND_DESKTOP,'result' ,'returned a non null value' ,MB_OK
        invoke CreateSolidBrush,[brush_clref]
        .if eax
        invoke MessageBox,HWND_DESKTOP,'ult' ,'cclr.rgbResult' ,name_buffer,MB_OK
        .endif
        ;invoke MessageBox,HWND_DESKTOP,'ult' ,'cclr.rgbResult' ,name_buffer,MB_OK
        mov [brush_handle],eax
        invoke SelectObject,[wparam],[brush_handle]
        invoke DeleteObject,[brush_handle]
        jmp .finish
  .apply_font:
        mov [cfont.lStructSize],sizeof.CHOOSEFONT
        mov [cfont.hwndOwner],$0
        mov [cfont.hInstance],edithwnd
        mov [cfont.hDC],$0
        mov [cfont.lpLogFont],lfont
        mov [cfont.iPointSize],$0
        mov [cfont.Flags],$0
        mov [cfont.rgbColors],$0
        mov [cfont.lCustData],$0
        mov [cfont.lpfnHook],$0
        mov [cfont.lpTemplateName],$0
        mov [cfont.lpszStyle],$0
        ;mov [cfont.nFontType],$0
        mov [cfont.nSizeMin],10
        mov [cfont.nSizeMax],100
        invoke ChooseFont,cfont
        .if eax
            invoke CreateFontIndirect,lfont
            invoke  SendMessage,[edithwnd],WM_SETFONT,eax
        .endif

        jmp .finish
  .apply_color:

        ;invoke SetTextColor,[edithwnd],0x000000FF
        ;mov [lParam],eax
        ;invoke  MessageBox,HWND_DESKTOP,lParam,lParam,MB_OK
        ;invoke  SendMessage,[edithwnd],WM_CTLCOLOREDIT,0x000000FF
        ;invoke COLORREF,

        mov [cclr.lpCustColors],cclr.lpCustColors
        mov [cclr.lStructSize],9*4
        mov [cclr.Flags],$2
        mov [cclr.hwndOwner],$0
        mov [cclr.hInstance],$0
        mov [cclr.rgbResult],$0
        mov [cclr.lCustData],$0
        mov [cclr.lpTemplateName],$0
        invoke ChooseColor,cclr
        mov eax, [cclr.rgbResult]
        mov [clr], eax
        invoke SetTextColor, [wparam], clr
                ;display cclr.rgbResult
        ;invoke  MessageBox,HWND_DESKTOP,clr,clr ,MB_OK
        ;invoke  CreateFont, 200, 0, 0, 255, 0, FALSE, FALSE, FALSE,\
        ;               DEFAULT_CHARSET, OUT_RASTER_PRECIS, CLIP_DEFAULT_PRECIS,\
        ;               \
        ;               ANTIALIASED_QUALITY,\   ; The font is antialiased or smoothed
        ;               \                       ; depending on its size.
        ;               \
        ;               FIXED_PITCH + FF_DONTCARE, "font"
        ;mov [font],eax
        ;invoke  SendMessage,[edithwnd],WM_SETFONT,font
        ;invoke  MessageBox,HWND_DESKTOP,cclr.rgbResult ,cclr.rgbResult ,name_buffer,MB_OK


        jmp .finish
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

  WSB_PROP_HBKGCOLOR=128h

  asm_filter db 'Text Files',0,'*.TXT;*.text;*.ASH',0
             db 'All files',0,'*.*',0
             db 0


  asm_extension db '.txt',0
  bfr dd ?
  hFile dd ?
  hFileWrite dd ?
  nSize dd ?
  result_of_reading dd ?
  result_of_writing dd ?
  get_text_content dd ?
  lpBytesRead dd ?
  lpBuffer rb 8192
  lpBytesWrite dd ?


  clr dd ?

  brush_clref dd ?
  brush_handle dd ?

  variable_buffer_size dd ?
  ofn OPENFILENAME

  cclr CHOOSECOLOR

  cfont CHOOSEFONT

  lfont LOGFONT

  _def_edit_proc dd ?

  font dd ?
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
          comctl32,'COMCTL32.DLL',\
          comdlg32,'comdlg32'

  include 'api\comdlg32.inc'
  include 'API\COMCTL32.INC'

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
         GetWindowLong,'GetWindowLongA',\
         CallWindowProc,'CallWindowProcW',\
         PostQuitMessage,'PostQuitMessage'

  import gdi,\
         CreateFont,'CreateFontA',\
         CreateSolidBrush,'CreateSolidBrush',\
         SelectObject,'SelectObject',\
         CreateFontIndirect,'CreateFontIndirectA',\
         SetTextColor,'SetTextColor',\
         DeleteObject,'DeleteObject'



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


       menuitem '&Text',0,MFR_POPUP
                menuitem '&Color',IDM_COLOR
                menuitem '&Font',IDM_FONT,MFR_END

       menuitem '&Graphics',0,MFR_POPUP
                menuitem '&Change Scrollbar Color',IDM_SCROLL_BAR_COLOR,MFR_END
       menuitem '&Help',0,MFR_POPUP + MFR_END
                menuitem '&About...',IDM_ABOUT,MFR_END

  icon main_icon,icon_data,'minipad.ico'

  versioninfo version,VOS__WINDOWS32,VFT_APP,VFT2_UNKNOWN,LANG_ENGLISH+SUBLANG_DEFAULT,0,\
              'FileDescription','MiniPad - example program',\
              'LegalCopyright','No rights reserved.',\
              'FileVersion','1.0',\
              'ProductVersion','1.0',\
              'OriginalFilename','MINIPAD.EXE'
