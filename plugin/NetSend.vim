"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" File:  "NetSend.vim"
" URL:  http://vim.sourceforge.net/script.php?script_id=1823
" Version: 1.2
" Last Modified: 14/03/2007
" Author: jmpicaza at gmail dot com
" Description: Plugin for sending messages with the net send MS command
" GetLatestVimScripts: 1823 1 :AutoInstall: NetSend.vim
" 
" TODO: Send the same message to more than one user.
" TODO: Optionally keep your messages and be able of re-send them to same or
"		other user.
"
" Overview
" --------
" Plugin for sending messages with the 'net send' MS command.
" It keeps the name of the users you send messages in a file and you can
" access them with the <tab> key.
" Navigation through menu (Plugin->NetSend->...) you can send messages, add users
" and remove them.
" You can also open the file with the user names and edit directly.
"
" Note: only works in the MS platform because there is where the 'NET SEND' command works.
"
" Installation
" ------------
" 1. Copy the NetSend.vim script to the $HOME/.vim/plugin or the
"    $HOME/vimfiles/plugin or the $VIM/vimfiles directory.  Refer to the
"    ':help add-plugin', ':help add-global-plugin' and ':help runtimepath'
"    topics for more details about Vim plugins.
" 2. Customisation:
" 		· Set the 'NetSend_File' variable in the .vimrc file to the location of a
"		  file to store the user names.
"			Example: let g:NetSend_File = $HOME ."/_netSend_Users"
"		· If you want a diferent message to be added to the message just add to
"		  your .vimrc: let g:NetSend_msg = "My initial message"
" 3. Restart Vim.
"
" Usage
" -----
" Insert :NetSend user_name message to this user
" 		 and user_name will recive a message saying:
" 		 	'myUser says: message to this user'
"
" Insert :NetSent <tab> to see the list of users you have stored.
" Insert :NetSent r<tab> to see all the users beginning by 'r', etc
"
" To edit the list of users just open the file used in the g:NetSend_File. You
" can do it Typing :EditNetSend or using the menu.
"
" History
" -------
"  1.2 Added compatibility with GetLatestVimScripts plugin.
"	   Some litle bugs fixed.
"  1.1 Added a menu for sending messages and adding and removing users
"  1.0 First version
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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
function! NetSend(arg)
	let to=split(a:arg)[0]
	if len(split(a:arg))==1
		let msg=inputdialog("Please insert the text for " . to , '','')
		if (len(msg)==0)
			echo "NET SEND to " .to. " ABORTED."
			return 0
		endif			
	else
		let msg=join(split(a:arg)[1:-1])
	endif
	let users=s:NetSendUsers(to,' ',' ')
	if exists('g:NetSend_msg')
		let msg=g:NetSend_msg . msg
	else
		let msg=expand('$USERNAME') . " says:" . msg
	endif
	if !count(users,to,1)
		call add(s:NetSend_Users,to)
		call sort(s:NetSend_Users)
		call writefile(s:NetSend_Users, g:NetSend_File)
		call s:NetSendMenu()
		echo "User '".to."' has been added to your users list file"
	endif
	let var="silent ! net send ".to." ".msg
	exe var
endfunc

" Assign commands to call the plugin
command! -nargs=1 -bang -complete=customlist,s:NetSendUsers NetSend call NetSend(<q-args>)
command! NetSendEdit :execute 'e ' . g:NetSend_File
" Assign names and load the initial menu
call s:NetSendMenu()

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save

