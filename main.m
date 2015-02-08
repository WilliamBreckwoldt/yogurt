%%=== YOGURT - A TASTY TREAT ===%%
% Created by William Breckwoldt
% Feel free to email me at yogurtQuestions@gmail.com with any questions.
% Make sure to update the version number after any changes to Spoon protocol!

function main %WELCOME TO THE PROGRAM

%% SETTING DEFAULTS

%=== NOTES ON PORT STUFF ===%
% For a useful list of what ports not to use:
% http://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
%
% From that page (as of 2/7/2015):
% "The range 49152–65535 (2^15 + 2^14 to 2^16 − 1) - above the registered ports - contains dynamic
% or private ports that cannot be registered with IANA. This range is used for custom or temporary
% purposes and for automatic allocation of ephemeral ports."
%
% The default Yogurt uses a port number (n = port number) for lid to be open for connections.
% The port (n+1) is open for connections to ShelfLife, for updating.
% The ports (n+2) to (n+11) are used for internal communications between Yogurt's child threads.
% Each user of spoon number (s = spoon number) will connect to a port (n+11+s).
% With a maxumum of (S) spoons, you will require a total of (S+12) ports in the range (n) to (n+11+S).
%
% If the ports you try won't work because they weren't closed properly, you will need delete the port objects.
% The code to do this looks something like this:
% portObjects = instrfindall;
% delete(portObjects)
% Please read the documentation on instrfindall and other port related functions.

Port = 51743;%Please read the above information, it's not too long and it's more decipherable than my shitty MATLAB code.
maxSpoons = 11;%Don't go too crazy. Each player requires their own port.

yogurtVersion = 'Ay00';

%% GETTING IP ADDRESS
systemInfo = instrhwinfo('tcpip');
IPString = systemInfo.LocalHost{1};
IPAddress = [];
for i = 1:length(IPString)
    if strcmp('/',IPString(i))
        IPAddress = IPString(i+1:length(IPString));
    end
end


%% CREATE GUI FIGURE
labelHeight = 20;
inputHeight = 20;
buttonHeight = 20;

mainFigure = figure(...
    'NumberTitle', 'off',...
    'Menubar', 'none',...
    'Name', ['main ',yogurtVersion],...
    'Position', [1,1,200,labelHeight+inputHeight+buttonHeight],...
    'Resize', 'off',...
    'CloseRequestFcn', @(src,~)closeMainFigure(src));
movegui(mainFigure, 'center')
pause(0.1)%This allows the gui to render


%% DECORATE THE GUI
uiIPAddress = uicontrol(...
    'Style', 'edit',...
    'Position', [1,buttonHeight+1,150,inputHeight],...
    'String', IPAddress,...
    'Callback', @(src,~)updateIP(src));
ipPort = uicontrol(...
    'Style', 'edit',...
    'Position', [151,buttonHeight+1,50,inputHeight],...
    'String', Port,...
    'Callback', @(src,~)updatePort(src));
uiIPAddressLabel = uicontrol(...
    'Style', 'text',...
    'Position', [1,buttonHeight+inputHeight+1,150,labelHeight],...
    'String', 'IP ADDRESS');
ipPortLabel = uicontrol(...
    'Style', 'text',...
    'Position', [151,buttonHeight+inputHeight+1,50,labelHeight],...
    'String', 'PORT');
uiStartYogurt = uicontrol(...
    'Style', 'pushbutton',...
    'Position', [1,1,200,buttonHeight],...
    'String', 'CREATE YOGURT',...
    'Callback', @(src,~)createYogurt(IPAddress,Port,maxSpoons,yogurtVersion,mainFigure));


%% main INTERNAL SUBFUNCTIONS
    function updateIP(src)
        IPAddress = get(src, 'String');
    end%updateIP

    function updatePort(src)
        Port = str2double(get(src, 'String'));
    end%updatePort

end%main


%% main EXTERNAL SUBFUNCTIONS
function closeMainFigure(src)
delete(src)
end%closeMainFigure


% ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== %


%% === START THE REAL SHIT - CREATING YOGURT === %%
% This stuff, Yogurt, is going to create the threads that will run Lid, Yeast, and ShelfLife.
% Yogurt will also read the logs of these functions, and manage the Yogurt GUI.

function createYogurt(IPAddress, Port, maxSpoons, yogurtVersion, src)

%% CREATE LOG FILES
sessionID = char(datetime('now','Format','y.MM-HH.mm.ss'));
fileName{1} = [sessionID,'_lid.log'];
fileName{2} = [sessionID,'_yeast.log'];
fileName{3} = [sessionID,'_shelflife.log'];
fileName{4} = [sessionID,'_yogurt.log'];
for i = 1:4
    fid = fopen(fileName{i},'w+');
    fileWrite(fid, 'LOG CREATED')
    fclose(fid);
end
fclose('all');
fid = fopen(fileName{4},'a');

%% REPLACE FIGURE

delete(src)%Deletes the original mainFigure

%yf stands for Yogurt figure
logWidth = 350;
logHeight = 600;
topDetailsHeight = 20;
bottomDetailHeight = 25;
yfHeight = logHeight + topDetailsHeight + bottomDetailHeight;
yfWidth = 4*logWidth;

jobEnded = 0;%yogurtFigure's callback references this variable, so we decare it before yogurtFigure
yogurtFigure = figure(...
    'NumberTitle', 'off',...
    'Menubar', 'none',...
    'Name', ['yogurtMain ',yogurtVersion],...
    'Position', [1,1,yfWidth,yfHeight],...
    'Resize', 'off',...
    'Visible', 'off',...
    'CloseRequestFcn', @(src,~)closeYogurtFigure(src));
movegui(yogurtFigure, 'center')
pause(0.1)%This allows the gui to render

%% DECORATE GUI

uiLocDisplay = uicontrol(...
    'Style', 'text',...
    'Position', [1,bottomDetailHeight+logHeight+1,logWidth,topDetailsHeight],...
    'FontSize', 10,...
    'String', [IPAddress,' \\ ',num2str(Port)]);
uiUsersDisplay = uicontrol(...
    'Style', 'text',...
    'Position', [logWidth+1,bottomDetailHeight+logHeight+1,logWidth,topDetailsHeight],...
    'FontSize', 10,...
    'String', 'CONNECTED USERS: 0');
uiVersionDisplay = uicontrol(...
    'Style', 'text',...
    'Position', [2*logWidth+1,bottomDetailHeight+logHeight+1,logWidth,topDetailsHeight],...
    'FontSize', 10,...
    'String', ['VERSION: ', yogurtVersion]);
uiExtraDisplay = uicontrol(...
    'Style', 'text',...
    'Position', [3*logWidth+1,bottomDetailHeight+logHeight+1,logWidth,topDetailsHeight],...
    'FontSize', 10,...
    'String', 'STATUS: delicious');

%LID LOG
uiLog{1} = uicontrol(...
    'Style', 'listbox',...
    'Enable', 'inactive',...
    'FontName', 'Courier New',...
    'Position', [1,bottomDetailHeight+1,logWidth,logHeight],...
    'String', {'LID LOG'});

%YEAST LOG
uiLog{2} = uicontrol(...
    'Style', 'listbox',...
    'Enable', 'inactive',...
    'FontName', 'Courier New',...
    'Position', [logWidth+1,bottomDetailHeight+1,logWidth,logHeight],...
    'String', {'YEAST LOG'});

%SHELFLIFE LOG
uiLog{3} = uicontrol(...
    'Style', 'listbox',...
    'Enable', 'inactive',...
    'FontName', 'Courier New',...
    'Position', [2*logWidth+1,bottomDetailHeight+1,logWidth,logHeight],...
    'String', {'SHELFLIFE LOG'});

%YOGURT LOG
uiLog{4} = uicontrol(...
    'Style', 'listbox',...
    'Enable', 'inactive',...
    'FontName', 'Courier New',...
    'Position', [3*logWidth+1,bottomDetailHeight+1,logWidth,logHeight],...
    'String', {'YOGURT LOG'});

yogurtIsConnected = 0;%uiDisconnectPushbutton's callback references this variable, so we decare it before uiDisconnectPushbutton
uiDisconnectPushbutton = uicontrol(...
    'Style', 'pushbutton',...
    'Position', [1,1,logWidth*4,bottomDetailHeight],...
    'String', 'END YOGURT',...
    'Callback',@(~,~)endYogurt());

%% CREATE WICKED THREADS
parallel.defaultClusterProfile('local');
localCluster = parcluster();

fileWrite(fid,'CREATING JOB')
yogurtJob = createJob(localCluster);
set(yogurtJob,'Name','yogurtJob')
yogurtTask{1} = createTask(yogurtJob, @runLid, 0, {fileName{1},IPAddress, Port, yogurtVersion, maxSpoons});
yogurtTask{2} = createTask(yogurtJob, @runYeast, 0, {fileName{2},IPAddress, Port, yogurtVersion, maxSpoons});
yogurtTask{3} = createTask(yogurtJob, @runShelfLife, 0, {fileName{3},IPAddress, Port, maxSpoons});
taskStatus = {'','',''};

submit(yogurtJob)

set(yogurtFigure, 'Visible', 'on')%At this point, we can make this visible without fearing it'll update and look stupid later.


%% OPEN CONNECTIONS

%Connection to Lid
yogurtLid = udp(IPAddress,'RemotePort',Port+4,'LocalPort',Port+9, 'Name', 'yogurtLid','DatagramReceivedFcn',@yogurtLidCall);
fopen(yogurtLid);

%Connection to Yeast
yogurtYeast = udp(IPAddress,'RemotePort',Port+6,'LocalPort',Port+10, 'Name', 'yogurtYeast','DatagramReceivedFcn',@yogurtYeastCall);
fopen(yogurtYeast);

%Connection to ShelfLife
yogurtShelfLife = udp(IPAddress,'RemotePort',Port+8,'LocalPort',Port+11, 'Name', 'yogurtShelfLife','DatagramReceivedFcn',@yogurtShelfLifeCall);
fopen(yogurtShelfLife);

fileWrite(fid,'INTERNAL CONNECTIONS OPENED')

%% MANAGE LOGS
managingLogs = 1;

%Open files with correct permission
for i = 1:4
    fileID(i) = fopen(fileName{i},'r');
end
tic;
%pingStart = 0;
pingString = [yogurtVersion,'USERNAMEPASSWORD0.0.0.0#########PING'];

while managingLogs

    %READ LOGS
    readLogs();

    %LID PING
    if toc > 180 && yogurtIsConnected %|| (toc > 20 && pingStart)
        fileWrite(fid, 'PINGING LID')
        %pingStart = 1;
        pingLid();
        tic;
    end

    %CHECK TASK ACTIVITY
    for t = 1:3
        currentState = char(yogurtTask{t}.State);
        if ~strcmp(taskStatus{t},currentState)
            taskStatus{t} = currentState;
            fileWrite(fid, ['TASK [',char(yogurtTask{t}.Function), '] IS [', taskStatus{t},']'])
        end
    end

    %TEST FOR CONNECTIVITY
    if  ~yogurtIsConnected && ~( strcmp(taskStatus{1},'pending') || strcmp(taskStatus{2},'pending') || strcmp(taskStatus{3},'pending') )
        pause(0.1)%Waiting to make sure the thread's connections have been made
        yogurtIsConnected = 1;%All tasks have finished pending
        fileWrite(fid,'INTERNAL CONNECTIONS ESTABLISHED')
    end

    %TEST FOR COMPLETION
    if ( strcmp(taskStatus{1},'finished') && strcmp(taskStatus{2},'finished') && strcmp(taskStatus{3},'finished') )
        managingLogs = 0;
    end

end


%CLOSING CONNECTIONS
fileWrite(fid,'CLOSING INTERNAL CONNECTIONS')
fclose(yogurtLid);
delete(yogurtLid);
fclose(yogurtYeast);
delete(yogurtYeast);
fclose(yogurtShelfLife);
delete(yogurtShelfLife);

fileWrite(fid,'WAITING FOR JOB TO END')
managingLogsClosing = 1;

while managingLogsClosing
    if ~jobEnded && strcmp(char(yogurtJob.State),'finished')
        delete(yogurtJob)
        jobEnded = 1;
        fileWrite(fid,'JOB HAS ENDED')
        fileWrite(fid,'YOGURT CAN NOW BE CLOSED')
    end
    pause(0.25)
    readLogs();
end

for i = 1:4
    fclose(fileID(i));
end

fclose(fid);%Closes Yogurt's log file
delete(yogurtFigure)

%% createYogurt INTERNAL SUBFUNCTIONS

    function readLogs()
        for i = 1:4
            logLine = fgetl(fileID(i));
            if ischar(logLine)
                logWrite(i,logLine)
            end
            pause(0.01)
        end
    end

    function yogurtYeastCall(~,~)
        fileWrite(fid, 'CONTACT FROM YEAST')
        numberOfPlayers = fread(yogurtYeast,1);
        set(uiUsersDisplay,'String',sprintf('CONNECTED USERS: %d',numberOfPlayers))
        fileWrite(fid, sprintf('CONNECTED USERS: %d',numberOfPlayers))
    end

    function pingLid()
        lidPing = tcpip(IPAddress, Port, 'NetworkRole', 'Client');
        fopen(lidPing);
        fread(lidPing,1);
        fwrite(lidPing,uint8(pingString),'uint8');
        fclose(lidPing);
        delete(lidPing);
    end

    function endYogurt()
        if yogurtIsConnected
            %TELL THREADS TO CLOSE
            fileWrite(fid,'SENDING THREAD CLOSE ORDER')
            fwrite(yogurtLid,0,'uint8')
            fwrite(yogurtYeast,0,'uint8')
            fwrite(yogurtShelfLife,0,'uint8')
            pingLid();%Ping Lid to ensure it recieves close command
            set(uiDisconnectPushbutton, 'Enable', 'off');
        else
            fileWrite(fid,'INTERNAL CONNECTIONS NOT ESTABLISHED')
            fileWrite(fid,'CLOSE ORDER CANNOT BE SENT')
        end
    end%endYogurt

    function closeYogurtFigure(src)
        if jobEnded %This function will only close the figure if the yogurtJob is finished.
            managingLogsClosing = 0;
        end
    end%closeYogurtFigure

    function logWrite(logNumber,inputString)
        maxLogLength = 100;
        logString = get(uiLog{logNumber},'String');
        if length(logString) >= maxLogLength
            set(uiLog{logNumber}, 'String', {logString{2:maxLogLength},inputString})
            set(uiLog{logNumber}, 'Value', maxLogLength)
        else
            set(uiLog{logNumber}, 'String', {logString{:},inputString})
            set(uiLog{logNumber}, 'Value', length(logString)+1)
        end

    end%logWrite

end%createYogurt


%% createYogurt EXTERNAL SUBFUNCTIONS


%
%
%%==== THIS IS THE END OF THE REAL SHIT ====%%


% ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== %


%% === LID === %%
% The Spoon has to get past the lid to get the Yogurt.
% This controls login. It waits for a connection, then sends back stuff.
% I need to comment this more.
function runLid(fileName, IPAddress, Port, yogurtVersion, maxSpoons)
fid = fopen(fileName,'a');
fileWrite(fid,'THREAD ACTIVE')

%% OPEN INTERNAL CONNECTIONS
%Connection to Yeast
lidYeast = udp(IPAddress,'RemotePort',Port+5,'LocalPort',Port+2, 'Name', 'lidYeast','DatagramReceivedFcn',@lidYeastCall);
fopen(lidYeast);

%Connection to ShelfLife
lidShelfLife = udp(IPAddress,'RemotePort',Port+7,'LocalPort',Port+3, 'Name', 'lidShelfLife','DatagramReceivedFcn',@lidShelfLifeCall);
fopen(lidShelfLife);

%Connection to Yogurt
lidYogurt = udp(IPAddress,'RemotePort',Port+9,'LocalPort',Port+4, 'Name', 'lidYogurt','DatagramReceivedFcn',@lidYogurtCall);
fopen(lidYogurt);

fileWrite(fid,'INTERNAL CONNECTIONS ESTABLISHED')

%% Lid Loop
assignmentPorts = zeros(1,maxSpoons);
assignmentPortValue = Port+11+1:Port+11+maxSpoons;
lidRun = 1;
lidSpoon = tcpip('0.0.0.0', Port, 'NetworkRole', 'Server','Name','lidSpoon')
while lidRun
    fileWrite(fid,[])
    fileWrite(fid,'WAITING FOR SPOON')
    pause(0.01)
    fopen(lidSpoon);
    fileWrite(fid,'SPOON CONNECTION ESTABLISHED')
    pause(0.1)
    fwrite(lidSpoon, 35, 'uint8');

    spoonRequest = fread(lidSpoon,[1,40]);
    fileWrite(fid,'NEW SPOON REQUEST:')

    spoonVersion = char(spoonRequest(1:4));
    fileWrite(fid,['  VERSION..: ',spoonVersion])

    if ~strcmp(spoonVersion,yogurtVersion)%Check version

        %UPDATE SPOON
        fileWrite(fid, 'SPOON IS OUT OF DATE')

        lidReply(Port+1)

    else%Version is up to date
        spoonUsernameChunk = spoonRequest(5:12);
        spoonUsername = char(spoonUsernameChunk(spoonUsernameChunk ~= 35));
        fileWrite(fid,['  USERNAME.: ',spoonUsername])

        spoonPasswordChunk = spoonRequest(13:20);
        spoonPassword = char(spoonPasswordChunk(spoonPasswordChunk ~= 35));
        fileWrite(fid,['  PASSWORD.: ',spoonPassword])

        spoonIPChunk = spoonRequest(21:36);
        spoonIP = char(spoonIPChunk(spoonIPChunk ~= 35));
        fileWrite(fid,['  IPADDRESS: ',spoonIP])

        spoonCommand = char(spoonRequest(37:40));
        fileWrite(fid,['  COMMAND..: ',spoonCommand])

        pause(0.1)

        if strcmp(spoonCommand,'PING')
            fileWrite(fid,'PING SUCCESS')

        elseif strcmp(spoonCommand,'NSPN')%New Spoon Command
            fileWrite(fid,'CREATION REQUEST')
            if creationVerify(spoonUsername,spoonPassword)
                fileWrite(fid,'CREATION REQUEST SUCCESS')
                lidReply(1);

            else%Spoon creation fails
                fileWrite(fid,'CREATION REQUEST FAILURE')
                lidReply(0);

            end

        elseif strcmp(spoonCommand,'LOGN')%Login Command
            fileWrite(fid,'LOGIN REQUEST')
            if loginVerify(spoonUsername,spoonPassword)

                fileWrite(fid,'LOGIN REQUEST SUCCESS')

                newPort = find(assignmentPorts == 0, 1);

                if ~isempty(newPort)%If there actually is a port that's open
                    fileWrite(fid,sprintf('PORT %d AVALIBLE', assignmentPortValue(newPort)))

                    assignmentPorts(newPort) = 1;

                    fileWrite(fid,'ASSIGNING SPOON TO PORT')

                    newPortString = lidReply(assignmentPortValue(newPort))%Sends assignment to Spoon
                    fwrite(lidYeast, [spoonIPChunk,uint8(newPortString)], 'uint8')%Sends assignment to Yogurt

                else%No avalible ports
                    fileWrite(fid,'NO AVALIBLE PORTS')
                    lidReply(Port);
                end
            else%Login fails
                fileWrite(fid,'LOGIN REQUEST FAILURE')
                lidReply(0);
            end
        else%Command not understood
            fileWrite(fid,'UNKNOWN COMMAND')
            lidReply('FAILURE');
        end%Command Check
    end%Version Check

    fclose(lidSpoon)
end%lidRun

fileWrite(fid,'CLOSING INTERNAL CONNECTIONS')

fclose(lidYeast);
delete(lidYeast);
fclose(lidShelfLife);
delete(lidShelfLife);
fclose(lidYogurt);
delete(lidYogurt);

fileWrite(fid,'ENDING THREAD')
fclose(fid);


%% lid INTERNAL SUBFUNCTIONS

function pReply = lidReply(r)%r for response, at most 7 characters.
    if ~ischar(r)
        r = num2str(r);
    end
    fileWrite(fid,['MESSAGING SPOON: ', r])
    pReply = [r,char(zeros(1,8-length(r))+35)];
    fwrite(lidSpoon, pReply, 'char');
end%lidReply


function lidYeastCall(~,~)
    fileWrite(fid,'CONTACT FROM YEAST')
    disconnectedSpoon = fread(lidYeast,1);
    assignmentPorts(disconnectedSpoon) = 0;
    fileWrite(fid, ['PORT ',char(assignmentPortValue(disconnectedSpoon)),' NOW OPEN'])
end

function lidYogurtCall(~,~)
    fileWrite(fid, 'CLOSE ORDER RECEIVED')
    lidRun = 0;
end%lidYogurtCall


end%runLid

%% lid EXTERNAL SUBFUNCTIONS

function check = creationVerify(username,password)
spoonFile = 'spoons.spoon';%If you change this, make sure you also change it in loginVerify
check = 0;
fid = fopen(spoonFile,'r');
checking = 1;

while checking
    checkLine = fgetl(fid);

    if ischar(checkLine)%next line of file
        L = length(checkLine);
        if L > 10
            lineType = checkLine(1:10);
            lineData = checkLine(11:L);
            if strcmp(lineType, 'USERNAME: ') && strcmp(lineData, username)
                checking = 0;
            end
        end
    else%end of file without finding username
        checking = 0;
        check = 1;
    end
end

fclose(fid);

if check
    fid = fopen(spoonFile,'a');
    fprintf(fid, 'USERNAME: %s\r\n', username);
    fprintf(fid, 'PASSWORD: %s\r\n\r\n', password);
    fclose(fid);
end

end%creationVerify


function check = loginVerify(username,password)
spoonFile = 'spoons.spoon';%If you change this, make sure you also change it in creationVerify
check = 0;
fid = fopen(spoonFile,'r');
checking = 1;

while checking
    checkLine = fgetl(fid);

    if ischar(checkLine)%next line of file
        L = length(checkLine);
        if L > 10
            lineType = checkLine(1:10);
            lineData = checkLine(11:L);
            if strcmp(lineType, 'USERNAME: ') && strcmp(lineData, username)
                checking = 0;

                passwordLine = fgetl(fid);
                pL = length(passwordLine);
                if pL > 10
                    passwordData = passwordLine(11:pL);
                    if strcmp(passwordData,password)
                        check = 1;
                    end%password check
                end%length check
            end%username check
        end%length check
    else%end of file without finding username
        checking = 0;
    end
end

fclose(fid);

end%loginVerify

%
%%==== END LID ====%%


% ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== %


%% === YEAST === %%
% The Yeast is what keeps the Yogurt alive.
% This is the internal operation of the server, the living part.
function runYeast(fileName, IPAddress, Port, yogurtVersion, maxSpoons)
fid = fopen(fileName,'a');
fileWrite(fid,'THREAD ACTIVE')

%% OPEN INTERNAL CONNECTIONS
%Connection to Lid
yeastLid = udp(IPAddress,'RemotePort',Port+2,'LocalPort',Port+5, 'Name', 'yeastLid','DatagramReceivedFcn',@yeastLidCall);
fopen(yeastLid);

%Connection to Yogurt
yeastYogurt = udp(IPAddress,'RemotePort',Port+10,'LocalPort',Port+6, 'Name', 'yeastYogurt','DatagramReceivedFcn',@yeastYogurtCall);
fopen(yeastYogurt);

fileWrite(fid,'INTERNAL CONNECTIONS ESTABLISHED')

%% GAME INITIALIZATION
% vvv This is non-essential to Yogurt
boardSize = 6;
BOARD = uint8(zeros(boardSize));
blankBoard = uint8(zeros(boardSize));
blankBlankBoard = uint8(zeros(boardSize));
positions = randi(boardSize,[maxSpoons,2]);
monster = [1,1];
y = 1;
x = 2;
% ^^^

yeastSpoon = {};%Initialize this so we can have the subfunctions modify them.
connectionPorts = zeros(1,maxSpoons);
spoonActivity = zeros(1,maxSpoons);
numPlayers = 0;
yeastRun = 1;
reductionInterval = 5;
rI = reductionInterval;%Just making it shorter
tic;
%% YEAST LOOP
while yeastRun
    
    %GAME STUFF
    % vvv This is non-essential to Yogurt
    %SEND OUT BOARD
    pause(0.02)

    blankBoard = blankBlankBoard;

    for s = connectionPorts(connectionPorts ~= 0)
        
%        while positions(s,x) == 0 || positions(s,y) == 0
%            fileWrite(fid,'FIXING POSITION 1')
%            testPosition = randi(boardSize,[1,2]);
%            fileWrite(fid,'FIXING POSITION 2')
%            if BOARD(testPosition(x),testPosition(y)) == 0
%                fileWrite(fid,'FIXING POSITION 3')
%                positions(s,x) = testPosition(x);
%                positions(s,y) = testPosition(y);
%                fileWrite(fid,'FIXING POSITION 4')
%            end
%            fileWrite(fid,'FIXING POSITION 5')
%        end
        blankBoard(positions(s,x),positions(s,y)) = s;
    end

    BOARD = blankBoard;

    for s = connectionPorts(connectionPorts ~= 0)
        fwrite(yeastSpoon{s}, s, 'uint8');
        fwrite(yeastSpoon{s}, BOARD(1:boardSize*boardSize), 'uint8');

    end

    %MOVE MONSTER
    % ^^^

    if toc > rI
        tic;
        spoonActivity = spoonActivity - rI;
        spoonActivity(spoonActivity <= -1) = -1;
        kickingSpoons = find(spoonActivity == 0);
        if ~isempty(kickingSpoons)
            for s = kickingSpoons
                fileWrite(fid, sprintf('SPOON %d IS INACTIVE',s))
                disconnectSpoon(s)
            end
        end
    end%Activity Check Stuff

end%yeastRun Loop

fileWrite(fid,'CLOSING INTERNAL CONNECTIONS')

fclose(yeastLid);
delete(yeastLid);
fclose(yeastYogurt);
delete(yeastYogurt);

fileWrite(fid,'ENDING THREAD')
fclose(fid);

    function yeastLidCall(~,~)
        activityStart = 60;
        fileWrite(fid,'CONTACT FROM LID')
        lidContact = char(fread(yeastLid,[1,24]));
        spoonIPAssignment = lidContact(uint8(lidContact(1:16)) ~= 35);
        spoonPortAssignment = str2double(lidContact(find(uint8(lidContact(17:24)) ~= 35) + 16));
        fileWrite(fid,lidContact)
        fileWrite(fid,spoonIPAssignment)
        fileWrite(fid,num2str(spoonPortAssignment))
        connectionNumber = spoonPortAssignment - Port - 11;
        fileWrite(fid,num2str(connectionNumber))

        yeastSpoon{connectionNumber} = udp(spoonIPAssignment,'RemotePort',spoonPortAssignment-100,'LocalPort',spoonPortAssignment, 'Name', sprintf('yeastSpoon%d',connectionNumber),'DatagramReceivedFcn',@(src,evt)yeastSpoonCall(src,evt,connectionNumber));
        fopen(yeastSpoon{connectiosrvnNumber});
        connectionPorts(connectionNumber) = connectionNumber;
        numPlayers = numPlayers + 1;
        spoonActivity(connectionNumber) = activityStart;
        fwrite(yeastYogurt,numPlayers,'uint8')
        fileWrite(fid,'SPOON CONNECTION COMPLETE')
    end

    function yeastSpoonCall(src,~,n)
        activityBump = 30;
        if spoonActivity(n) < activityBump
            spoonActivity(n) = activityBump;
        end

        command = char(fread(src,[1,4]))
        move = [0,0];
        if strcmp(command, 'EXIT')
            fileWrite(fid, sprintf('SPOON %d DISCONNECTION COMMAND', n))
            disconnectSpoon(n)
        elseif strcmp(command,'MU##')
            fileWrite(fid, sprintf('SPOON %d MOVE UP COMMAND', n))
            move = [1,0];
        elseif strcmp(command,'MD##')
            fileWrite(fid, sprintf('SPOON %d MOVE DOWN COMMAND', n))
            move = [-1,0];
        elseif strcmp(command,'ML##')
            fileWrite(fid, sprintf('SPOON %d MOVE LEFT COMMAND', n))
            move = [0,-1];
        elseif strcmp(command,'MR##')
            fileWrite(fid, sprintf('SPOON %d MOVE RIGHT COMMAND', n))
            move = [0,1];
        end

        newPosition = mod(positions(n,:) + move - 1, boardSize) + 1;
        if BOARD(newPosition(x),newPosition(y)) == 0
            positions(n,:) = newPosition;
        end

    end

    function disconnectSpoon(spoonNumber)
        fclose(yeastSpoon{spoonNumber})
        connectionPorts(spoonNumber) = 0;
        numPlayers = numPlayers - 1;
        fwrite(yeastYogurt, numPlayers,'uint8')
        fwrite(yeastLid, spoonNumber,'uint8')
        pingLid();
        fileWrite(fid, sprintf('SPOON %d HAS BEEN DISCONNECTED',s))
    end

    function yeastYogurtCall(~,~)
        fileWrite(fid, 'CLOSE ORDER RECEIVED')
        yeastRun = 0;
    end

    function pingLid()
        fileWrite(fid,'PINGING LID')
        pingString = [yogurtVersion,'USERNAMEPASSWORD0.0.0.0#########PING'];
        lidPing = tcpip(IPAddress, Port, 'NetworkRole', 'Client');
        fopen(lidPing);
        fread(lidPing,1);
        fwrite(lidPing,uint8(pingString),'uint8');
        fclose(lidPing);
        delete(lidPing);
        fileWrite(fid,'LID PING COMPLETE')
    end

end
%
%%==== END YEAST ====%%


% ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== % ===== %


%% === SHELFLIFE === %%
% You never want Yogurt past its ShelfLife.
% This is the updating process, a Spoon will connect here after it is sent by Lid.
% Once connected, the Spoon will be sent the code for an updated Spoon client.
function runShelfLife(fileName, IPAddress, Port, maxSpoons)
fid = fopen(fileName,'a');
fileWrite(fid,'THREAD ACTIVE')

%% OPEN INTERNAL CONNECTIONS
%Connection to Lid
shelfLifeLid = udp(IPAddress,'RemotePort',Port+3,'LocalPort',Port+7,'Name','shelfLifeLid','DatagramReceivedFcn',@shelfLifeLidCall);
fopen(shelfLifeLid);

%Connection to Yogurt
shelfLifeYogurt = udp(IPAddress,'RemotePort',Port+11,'LocalPort',Port+8,'Name','shelfLifeYogurt','DatagramReceivedFcn',@shelfLifeYogurtCall);
fopen(shelfLifeYogurt)

fileWrite(fid,'INTERNAL CONNECTIONS ESTABLISHED')

shelfLifeRun = 1;
shelfLifeSpoon = tcpip('0.0.0.0', Port, 'NetworkRole', 'Server','Name','shelfLifeSpoon')
while shelfLifeRun
    fileWrite(fid,[])
    fileWrite(fid,'WAITING FOR SPOON')
    pause(0.01)
    fopen(shelfLifeSpoon);
    fileWrite(fid,'SPOON CONNECTION ESTABLISHED')

    FID = fopen('spoon.m','r');
    dataIn = '@';
    l = 0;
    while ischar(dataIn)
        l = l + 1;
        dataIn = fgetl();
        fileWrite(fid,sprintf('LINE %d READ',l))
        if ~ischar(dataIn)
            dataIn = '@';
            fileWrite(fid,'END OF FILE REACHED')
        end
        fwrite(shelfLifeSpoon, dataIn, 'uint8');
    end

    fclose(FID);
    fclose(shelfLifeSpoon);

end


fileWrite(fid,'CLOSING INTERNAL CONNECTIONS')

fclose(shelfLifeLid);
delete(shelfLifeLid);
fclose(shelfLifeYogurt);
delete(shelfLifeYogurt);

fileWrite(fid,'ENDING THREAD')
fclose(fid);


%INTERNAL SUBFUNCTIONS

    function shelfLifeYogurtCall
        fileWrite(fid, 'CLOSE ORDER RECEIVED')
        shelfLifeRun = 0;
    end

end%runShelfLife
%
%%==== END SHELFLIFE ====%%





%% SUBFUNCTIONS THAT ARE USEFUL TO ALL PARTS OF YOGURT
function fileWrite(fileID,inputString)
writeTime = char(datetime('now','Format','HH:mm:ss'));
fprintf(fileID, '[%s]: %s\r\n', writeTime, inputString);
end

%% THE END OF THE LINE
% Congratulations, you've made it.
% Your task is to make something better with it.