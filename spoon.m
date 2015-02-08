%%=== SPOON - LET'S GET SOME YOGURT ===%%
% Created by William Breckwoldt
% Feel free to email me at yogurtQuestions@gmail.com with any questions.

function spoon %BECAUSE FORKS ARE DUMB

%% SET SOME DEFAULT SHIT

DefaultIPAddress = '129.22.145.35';
DefaultPort = 51743;

spoonVersion = 'Ay00';%This is very important, please don't just change this instead of updating.
spoonCommand = 'LOGN';

connectionIP = DefaultIPAddress;%connectionIP is what Spoon will end up sending to Lid as spoonConnectionIP
connectionPort = num2str(DefaultPort);%connectionPort is what Spoon will end up sending to Lid as spoonConnectionPort

BOARD = [];
selfNum = 1;
selfColor = 'blue';
otherColor = 'red';
emptyColor = 'white';

%% CREATE GUI FIGURE
labelHeight = 20;
inputHeight = 20;
buttonHeight = 20;

spoonFigure = figure(...
    'NumberTitle', 'off',...
    'Menubar', 'none',...
    'Name', ['spoon ',spoonVersion ],...
    'Position', [1,1,200,labelHeight+inputHeight+inputHeight+buttonHeight],...
    'Resize', 'off');
movegui(spoonFigure, 'center')
pause(0.1)%This allows the gui to render

%% ITEMS FOR SETTINGS MENU

numberOfSettings = 3;

IPSetting = 1;
PortSetting = 2;
flavorSetting = 3;

settingName{1} = 'Connection IP:';
settingName{2} = 'Connection Port:';
settingName{3} = 'Yogurt Flavor:';

settingDefault{1} = DefaultIPAddress;
settingDefault{2} = num2str(DefaultPort);
settingDefault{3} = 'strawberry';

%% DECORATE THE GUI
uiUsername = uicontrol(...
    'Style', 'edit',...
    'Position', [1,buttonHeight+inputHeight+1,100,inputHeight],...
    'String', ['test']);
uiPassword = uicontrol(...
    'Style', 'edit',...
    'Position', [101,buttonHeight+inputHeight+1,100,inputHeight],...
    'String', ['123']);
uiUsernameLabel = uicontrol(...
    'Style', 'text',...
    'Position', [1,buttonHeight+2*inputHeight+1,100,labelHeight],...
    'String', 'USERNAME');
uiPasswordLabel = uicontrol(...
    'Style', 'text',...
    'Position', [101,buttonHeight+2*inputHeight+1,100,labelHeight],...
    'String', 'PASSWORD');
uiContactLid = uicontrol(...
    'Style', 'pushbutton',...
    'Position', [1,1,200,buttonHeight],...
    'String', 'CONTACT LID',...
    'Callback', @contactLid);
uiNewSpoon = uicontrol(...
    'Style', 'checkbox',...
    'Position', [1,buttonHeight+1,100,buttonHeight],...
    'String', 'NEW SPOON',...
    'Callback', @toggleNew);
uiSettings = uicontrol(...
    'Style', 'pushbutton',...
    'Position', [101,buttonHeight+1,100,buttonHeight],...
    'String', 'SETTINGS',...
    'Callback', @settingsMenu);



%% === contact Lid === %%
% In this function, we make initial contact with Yogurt.
% It is important to always have the 4-character version number sent fist, so ShelfLife can update Spoon if neccessary.

	function contactLid(~,~)
	%% CREATING THE SPOON'S REQUEST
	% The request is 5 parts in 40 bytes, shown as PART NAME (BYTES USED):
	% Version Number (4), Username (8), Password (8), IP Address (16), Command (4).


	%VERSION NUMBER
	%spoonVersion should already be in the correct form.

	%USERNAME
	usernameMaxLength = 8;%Changing this will require changes in the Spoon to Lid protocol.
	usernameMinLength = 3;%Changing this is easy.
	username = get(uiUsername, 'String');
	spoonUsername = [];
	uL = length(username);

	%Checking to see if each character is valid
	validUsername = 1;
	validCharacterNumbers = [95,45:46,48:57,65:90,97:122];
	for i = 1:uL
		if ~sum(uint8(username(i)) == validCharacterNumbers)% Will return 0 if the character is a valid character
			validUsername = 0;
		end
	end

	if validUsername
		if uL > 8
			errorMessage('USERNAME TOO LONG','Username must be under 8 characters')
		elseif uL < 3
			errorMessage('NOT ENOUGH PYLONS','Username must be at least 3 characters')
		elseif uL == 8
			spoonUsername = username;
		else
			spoonUsername = [username,char(zeros(1,8-uL)+35)];
		end
	else
		errorMessage('INVALID USERNAME',{'Your Username contained invalid characters.','Valid Characters:',char(validCharacterNumbers)})
	end

	%PASSWORD
	passwordMaxLength = 8;%Changing this will require changes in the Spoon to Lid protocol.
	passwordMinLength = 3;%Changing this is easy.
	password = get(uiPassword, 'String');
	spoonPassword = [];
	pL = length(password);

	%Checking to see if each character is valid
	validPassword = 1;%What characters are valid is set in %USERNAME, above
	for i = 1:pL
		if ~sum(uint8(password(i)) == validCharacterNumbers)% Will return 0 if the character is a valid character
			validPassword = 0;
		end
	end

	if validPassword
		if pL > 8
			errorMessage('PASSWORD TOO LONG','Password must be under 8 characters')
		elseif pL < 3
			errorMessage('NOT ENOUGH PYLONS','Password must be at least 3 characters')
		elseif pL == 8
			spoonPassword = password;
		else
			spoonPassword = [password,char(zeros(1,8-pL)+35)];
		end
	else
		errorMessage('INVALID PASSWORD',{'Your Password contained invalid characters.','Valid Characters:',char(validCharacterNumbers)})
	end

	%IP ADDRESS
	IPL = length(connectionIP);
	if IPL <= 15
		spoonConnectionIP = [connectionIP,char(zeros(1,16-IPL)+35)];
	else
		errorMessage('INVALID IP ADDRESS',{'The IP Address you are trying to connect to appears to be too long.','Attempted IP Address:',connectionIP})
	end

	%COMMAND
	%spoonCommand should already be in the correct form.


	sendString = [spoonVersion,spoonUsername,spoonPassword,spoonConnectionIP,spoonCommand];
	if length(sendString) == 40
		spoonLid = tcpip(connectionIP, str2num(connectionPort), 'NetworkRole', 'Client');
		fopen(spoonLid);
		fread(spoonLid,1);
		fwrite(spoonLid,uint8(sendString),'uint8')
		pause(0.1)

		portAssignment = fread(spoonLid,[1,8]);
		Port = str2double(char(portAssignment(portAssignment ~= 35)));

		fclose(spoonLid)
		delete(spoonLid)
		pause(0.1)
		if strcmp(char(portAssignment(portAssignment ~= 35)),'FAILURE')
			errorMessage('COMMAND NOT UNDERSTOOD','Yogurt isn''t sure what you''re trying to do with that.')
		elseif Port == 0
			if strcmp(spoonCommand,'LOGN')
				errorMessage('LOGIN FAILURE','What''s your mother''s maiden name?')
			elseif strcmp(spoonCommand,'NSPN')
				errorMessage('ACCOUNT CREATION ERROR','I''m pretty sure someone already has that username.')
			end	
		elseif Port == 1
			if strcmp(spoonCommand,'NSPN')
				errorMessage('ACCOUNT CREATION SUCCESS',{'Your account was created.',['USERNAME: ',username],['PASSWORD: ',password]})
			end
		elseif Port == str2num(connectionPort)
			errorMessage('SERVER AT MAXIMUM CAPACITY',{'No more Spoons can fit in this Yogurt.','Please try again later.'})
		elseif Port == str2num(connectionPort) + 1
			errorMessage('VERSION OUT OF DATE','This is and old version of Spoon.')
		else
			yeastConnection = udp(connectionIP,'RemotePort',Port,'LocalPort',Port-100,'DatagramReceivedFcn',@spoonYeastCall);
			fopen(yeastConnection);

			delete(spoonFigure)

			runGame(yeastConnection)

			fclose(yeastConnection);
			delete(yeastConnection);

		end
	end

	end%contactLid
%
%
%%=== END contactLid ===%%



%% == toggleNew == %%
%This toggles the sent command between two values.
%The default values mean 'create a new account' and 'login with this account'
	function toggleNew(~,~)
		if get(uiNewSpoon,'Value')%Value of the checkbox, this will be 1 if 'NEW' is checked
			spoonCommand = 'NSPN'; %New SPooN
		else
			spoonCommand = 'LOGN'; %LOGiN
		end

	end%toggleNew
%
%
%%=== END toggleNew ===%%



%% == settingsMenu == %%
% This menu is used to update the default connection settings of Spoon to Lid.
% The default ports are assigned in the
	function settingsMenu(~,~)
		displayWidth = 100;
		inputWidth = 100;
		settingHeight = 25;

		settingsFigure = figure(...
		    'NumberTitle', 'off',...
		    'Menubar', 'none',...
		    'Name', 'settings',...
		    'Position', [1,1,inputWidth+displayWidth,settingHeight*(numberOfSettings+1)],...
		    'Resize', 'off');
		movegui(settingsFigure, 'center')
		pause(0.1)%This allows the gui to render

		for i = 1:numberOfSettings
			uiSettingDisplay(i) = uicontrol(...
			    'Style', 'text',...
			    'Position', [1,1+settingHeight*(numberOfSettings-i+1),displayWidth,settingHeight],...
			    'String', settingName{i});
			uiSettingInput(i) = uicontrol(...
			    'Style', 'edit',...
			    'Position', [displayWidth+1,1+settingHeight*(numberOfSettings-i+1),inputWidth,settingHeight],...
			    'String', settingDefault{i});
		end
		uiSettingExit = uicontrol(...
		    'Style', 'pushbutton',...
		    'Position', [1,1,inputWidth+displayWidth,settingHeight],...
		    'String', 'APPLY CHANGES',...
		    'Callback',@applySettings);

		function applySettings(~,~)
			connectionIP = get(uiSettingInput(IPSetting),'String');
			connectionPort = get(uiSettingInput(PortSetting),'String');
			connectionFlavor = get(uiSettingInput(flavorSetting),'String');
			settingDefault{IPSetting} = connectionIP;
			settingDefault{PortSetting} = connectionPort;
			settingDefault{flavorSetting} = connectionFlavor;
			for i = 1:numberOfSettings
				set(uiSettingInput(i),'Enable', 'off')
			end
		end
	end
%
%
%%=== END settingsMenu ===%%


function spoonYeastCall(src,evt)
boardSize = 6;
dataLength = evt.Data.DatagramLength;
if dataLength == 1
	selfNum = fread(src,1);
else
	BOARD = fread(src,[boardSize,boardSize]);
end
end%spoonYeastCall


%% === runGame === %%
%
%
function runGame(yeastConnection)
disp(BOARD)
boardSize = 6;
boxSize = 50;
gameFigure = figure(...
    'NumberTitle', 'off',...
    'Menubar', 'none',...
    'Name', ['spoon ',spoonVersion ],...
    'Position', [1,1,boxSize*boardSize,boxSize*boardSize],...
    'KeyPressFcn', @gameInput,...
    'CloseRequestFcn', @gameClose,...
    'Resize', 'off');
movegui(gameFigure, 'center')
pause(0.1)%This allows the gui to render

for i = 1:boardSize;
	for j = 1:boardSize;
		gameBox(i,j) = uicontrol(...
		    'Style', 'edit',...
		    'Enable', 'Inactive',...
		    'ForegroundColor', emptyColor,...
		    'BackgroundColor', emptyColor,...
		    'Position', [boxSize*(i-1)+1,boxSize*(j-1)+1,boxSize,boxSize],...
		    'String', '0');
	end
end

gameRun = 1;
while gameRun
	pause(0.01)
	for i = 1:boardSize;
		for j = 1:boardSize;
				set(gameBox(i,j), 'String', num2str(BOARD(i,j)))
			if BOARD(i,j) == selfNum
				set(gameBox(i,j), 'BackgroundColor', selfColor)
			elseif BOARD(i,j) == 0
				set(gameBox(i,j), 'BackgroundColor', emptyColor)
			else
				set(gameBox(i,j), 'BackgroundColor', otherColor)
			end
		end
	end
end

delete(gameFigure)

function gameInput(~,evt)
	keyIn = char(evt.Key);
	if strcmp(keyIn,'escape')
		sendCommand('EXIT')
	elseif strcmp(keyIn,'w') || strcmp(keyIn,'uparrow')
		sendCommand('MU##')
	elseif strcmp(keyIn,'s') || strcmp(keyIn,'downarrow')
		sendCommand('MD##')
	elseif strcmp(keyIn,'a') || strcmp(keyIn,'leftarrow')
		sendCommand('ML##')
	elseif strcmp(keyIn,'d') || strcmp(keyIn,'rightarrow')
		sendCommand('MR##')
	end
end


function gameClose(~,~)
	gameRun = 0;
	sendCommand('EXIT')
end


function sendCommand(command)
	fwrite(yeastConnection, char(command), 'char')
end


end%runGame
%
%
%%==== end runGame ====%%

end%spoon

%% spoon EXTERNAL SUBFUNCTIONS

function errorMessage(title,errorText)%Writes an error message
	h = 100;
	w = 400;
	errorFigure = figure(...
    'NumberTitle', 'off',...
    'Menubar', 'none',...
    'Name', [title],...
    'Position', [1,1,w,h],...
    'Resize', 'off');
    iuError = uicontrol(...
    'Style', 'text',...
    'Position', [1,1,w,h],...
    'String', errorText);
movegui(errorFigure, 'center')
pause(0.1)%This allows the gui to render
end%errorMessage