" File:  "NetSend.vim"
" URL:  http://vim.sourceforge.net/script.php?script_id=
" Version: 1.1
" Last Modified: 12/03/2007
" Author: jmpicaza at gmail dot com
" Description: Plugin for sending messages with the net send MS command
"
" TODO: write the unix/linux version (smbclient -M MS-Windows-host-name OR
" talk)
"
" Overview
" --------
" Plugin for sending messages with the net send MS command.
" Only works in the MS platform because is where the 'NET SEND' command works.
"
" Installation
" ------------
" 1. Copy the NetSend.vim script to the $HOME/.vim/plugin or the
"    $HOME/vimfiles/plugin or the $VIM/vimfiles directory.  Refer to the
"    ':help add-plugin', ':help add-global-plugin' and ':help runtimepath'
"    topics for more details about Vim plugins.
" 2. Set the NetSend_File Vim variable in the .vimrc file to the location of a
"    file to store the user names.
"    Example: let g:NetSend_File = $HOME ."/_netSend_Users"
" 3. If you want a diferent message to be added to the message just add to
"    your .vimrc: let g:NetSend_msg = "My initial message"
" 4. Restart Vim.
"
" Usage
" -----
" Insert :NetSend user_name message to this user
" 		 and user_name will recive a message saying:
" 		 	'myUser says: message to this user'
"
" Insert :NetSent <tab> to see the list of users you have stored.
" Insert :NetSent r<tab> to see all the users beginning by 'r'
"
" To edit the list of users just open the file used in the g:NetSend_File. You
" can do it Typing :EditNetSend
"
" History
" -------
"  1.1 Added a menu for sending messages and adding and removing users
"  1.0 First version

if exists('loaded_netsend')
    finish
endif
let loaded_netsend=1

" Line continuation used here
let s:cpo_save = &cpo
set cpo&vim

" To assign the file for keeping the user names
if !exists('g:NetSend_File')
    if has('unix')
        let g:NetSend_File = $HOME . "/.netSend_Users"
    else
        let g:NetSend_File = $VIM . "/_netSend_Users"
    endif
endif

" To load the NetSend list from the NetSend file
function! s:NetSend_LoadList()
    " Read the list from the NetSend file.
    if filereadable(g:NetSend_File)
        let s:NetSend_Users=readfile(g:NetSend_File)
		if len(s:NetSend_Users) == 0
			let s:NetSend_Users=[expand('$USERNAME')]
		endif
	else
		let s:NetSend_Users=[expand('$USERNAME')]
		" Create the file if not exists
		call writefile(s:NetSend_Users, g:NetSend_File)
    endif
endfunction

" Function for managing the user autocompletion
function! s:NetSendUsers(A,L,P)
    call s:NetSend_LoadList()

	call sort(s:NetSend_Users)
	let aux=s:NetSend_Users[:]

	if a:A==''
		let sub=s:NetSend_Users[:]
	else
		call filter(aux, 'v:val =~ "\^".a:A.".*"')
		if (len(aux)==0)
			let sub=s:NetSend_Users[:]
		else
			let sub=aux[:]
		endif
	endif
	return sub[:]
endfunc

" To add a user
function! NetSendAdd()
	call s:NetSend_LoadList()
	let user=inputdialog("Please insert the user name to add to the users list", '', '')
	if (count(s:NetSend_Users, user) == 0)
		call add(s:NetSend_Users, user)
		call sort(s:NetSend_Users)
		call writefile(s:NetSend_Users, g:NetSend_File)
		call s:NetSendMenu()
	else
		echo "User " . user . " is already in the list"
	endif
endfunc

" To remove a user
function! NetSendRemove(user)
	call s:NetSend_LoadList()
	call remove(s:NetSend_Users, index(s:NetSend_Users, a:user,0,1))
	call writefile(s:NetSend_Users, g:NetSend_File)
	call s:NetSendMenu()
endfunc

" Menu items
function! s:NetSendMenu()
	silent! aunmenu &Plugin.NetSend
	call s:NetSend_LoadList()
	for user in s:NetSend_Users
		exe 'amenu &Plugin.NetSend.Send\ Message.' . user . " :NetSend " . user . "<cr>"
		exe 'amenu &Plugin.NetSend.Manage\ Users.Remove.' . user . " :call NetSendRemove('" . user . "')<cr>"
	endfor
	amenu &Plugin.NetSend.Manage\ Users.Add  :call NetSendAdd()<cr>
	amenu &Plugin.NetSend.Manage\ Users.Edit\ Users\ File :NetSendEdit<cr>
endfunc

" Main function (Send a message through NET SEND command)
function! NetSend(to, ...)
	let users=s:NetSendUsers(a:to,' ',' ')
	if exists('g:NetSend_msg')
		let msg=g:NetSend_msg
	else
		let msg=expand('$USERNAME') . " says:"
	endif
	if !count(users,a:to,1)
		call add(s:NetSend_Users,a:to)
		call sort(s:NetSend_Users)
		call writefile(s:NetSend_Users, g:NetSend_File)
		call s:NetSendMenu()
		echo "User '".a:to."' has been added to your users list file"
	endif
	if a:0 == 0
		let msg=msg . " " . inputdialog("Please insert the text for " . a:to , '',' NO TEXT')
	else
		for s in a:000
			let msg=msg . " " . s
		endfor
	endif
	let var="silent ! net send ".a:to." ".msg
	exe var
endfunc

" Assign commands to call the plugin
command! -nargs=+ -bang -complete=customlist,s:NetSendUsers NetSend call NetSend(<f-args>)
command! NetSendEdit :execute 'e ' . g:NetSend_File
" Assign names and load the initial menu
call s:NetSendMenu()

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save

