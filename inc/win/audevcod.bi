'' FreeBASIC binding for mingw-w64-v4.0.1
''
'' based on the C header files:
''   This Software is provided under the Zope Public License (ZPL) Version 2.1.
''
''   Copyright (c) 2009, 2010 by the mingw-w64 project
''
''   See the AUTHORS file for the list of contributors to the mingw-w64 project.
''
''   This license has been certified as open source. It has also been designated
''   as GPL compatible by the Free Software Foundation (FSF).
''
''   Redistribution and use in source and binary forms, with or without
''   modification, are permitted provided that the following conditions are met:
''
''     1. Redistributions in source code must retain the accompanying copyright
''        notice, this list of conditions, and the following disclaimer.
''     2. Redistributions in binary form must reproduce the accompanying
''        copyright notice, this list of conditions, and the following disclaimer
''        in the documentation and/or other materials provided with the
''        distribution.
''     3. Names of the copyright holders must not be used to endorse or promote
''        products derived from this software without prior written permission
''        from the copyright holders.
''     4. The right to distribute this software or to use it for any purpose does
''        not give you the right to use Servicemarks (sm) or Trademarks (tm) of
''        the copyright holders.  Use of them is covered by separate agreement
''        with the copyright holders.
''     5. If any files are modified, you must cause the modified files to carry
''        prominent notices stating that you changed the files and the date of
''        any change.
''
''   Disclaimer
''
''   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY EXPRESSED
''   OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
''   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
''   EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY DIRECT, INDIRECT,
''   INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
''   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
''   OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
''   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
''   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
''   EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
''
'' translated to FreeBASIC by:
''   Copyright © 2015 FreeBASIC development team

#pragma once

#define __AUDEVCOD__

type _tagSND_DEVICE_ERROR as long
enum
	SNDDEV_ERROR_Open = 1
	SNDDEV_ERROR_Close = 2
	SNDDEV_ERROR_GetCaps = 3
	SNDDEV_ERROR_PrepareHeader = 4
	SNDDEV_ERROR_UnprepareHeader = 5
	SNDDEV_ERROR_Reset = 6
	SNDDEV_ERROR_Restart = 7
	SNDDEV_ERROR_GetPosition = 8
	SNDDEV_ERROR_Write = 9
	SNDDEV_ERROR_Pause = 10
	SNDDEV_ERROR_Stop = 11
	SNDDEV_ERROR_Start = 12
	SNDDEV_ERROR_AddBuffer = 13
	SNDDEV_ERROR_Query = 14
end enum

type SNDDEV_ERR as _tagSND_DEVICE_ERROR
const EC_SND_DEVICE_ERROR_BASE = &h0200
#define EC_SNDDEV_IN_ERROR (EC_SND_DEVICE_ERROR_BASE + &h00)
#define EC_SNDDEV_OUT_ERROR (EC_SND_DEVICE_ERROR_BASE + &h01)
