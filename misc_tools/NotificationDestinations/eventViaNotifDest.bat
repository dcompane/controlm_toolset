@echo off

:: (c) 2020 - 2024 Daniel Companeetz, BMC Software, Inc.
:: All rights reserved.
:: 
:: BSD 3-Clause License
:: 
:: Redistribution and use in source and binary forms, with or without
:: modification, are permitted provided that the following conditions are met:
:: 
:: 1. Redistributions of source code must retain the above copyright notice, this
::    list of conditions and the following disclaimer.
:: 
:: 2. Redistributions in binary form must reproduce the above copyright notice,
::    this list of conditions and the following disclaimer in the documentation
::    and/or other materials provided with the distribution.
:: 
:: 3. Neither the name of the copyright holder nor the names of its
::    contributors may be used to endorse or promote products derived from
::    this software without specific prior written permission.
:: 
:: THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
:: AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
:: IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
:: DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
:: FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
:: DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
:: SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
:: CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
:: OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
:: OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
:: 
:: SPDX-License-Identifier: BSD-3-Clause
:: For information on SDPX, https://spdx.org/licenses/BSD-3-Clause.html

:: Change Log
:: Date (YMD)    Name                  What
:: --------      ------------------    ------------------------
:: 20240318      Daniel Companeetz     Initial work

REM ==================================
REM Usage: use the notification destination
REM        The message should be in two parts separated by space:
REM        -->event DATE<--
REM           where DATE is ODAT STAT MMDD

FOR /F "tokens=1" %%i IN (%2) DO (set event=%%i)
FOR /F "tokens=2" %%i IN (%2) DO (set odat=%%i)
FOR /F "tokens=3" %%i IN (%2) DO (set log=%%i)

if /I NOT .%log% == .Y goto NoLog

REM This line may need to be adequated to the date format of the date variable
REM   use "echo %date%" to see the format and adapt it
set currdir=%~dp0
set currdate=%date:~-4,4%_%date:~-10,2%_%date:~-7,2%
set currtime=%time:~0,2%_%time:~3,2%_%time:~6,2%
REM Since the event should be different in all instances, use that for the file name
REM   Coupled with date and time should make for a unique file name
REM   Reason: Windows locks the redirected file when writing and other scripts will fail.
set logfile=%currdir%%currdate%_%currtime%_%event%.txt

echo Current date: %currdate% >> %logfile%
echo Current time: %time%  %currtime% >> %logfile%
echo Parameters: %* >> %logfile%
ctm run event::add IN01 %event% %odat% >> %logfile% 2>&1
exit /b %ERRORLEVEL%

:NoLog
ctm run event::add IN01 %event% %odat%