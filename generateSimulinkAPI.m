function generateSimulinkAPI(systemName,varargin)
% Helps to generate the Model Construction Simulink API codes for given
% Model or Subsystem.
%
%Syntax:
%     >> generateSimulinkAPI(systemName)
%        Prints the API for the given system in the command window.
%
%     >> generateSimulinkAPI(systemName,filename)
%         Writes the API for the given system in the specified file.
%
% systemName - It can be a simulink model or the subsystem.
%
% Example:
%     >> generateSimulinkAPI('sldemo_absbrake')
%        Prints the API for the 'sldemo_absbrake' in the command window.
%
%     >> generateSimulinkAPI('sldemo_absbrake','sample.m')
%         Writes the API for the 'sldemo_absbrake' in the file 'sample.m'.
%
% Contact: contactus@sysenso.com
%

%--------------------------------------------------------------------------
%% Validate inputs.
if nargin>1
    fid = fopen(varargin{1},'W+');
else
    fid = 1;
end
%--------------------------------------------------------------------------
load_system(systemName);
if strcmpi(systemName,bdroot(systemName))
    modelLevelAPI = true;
else
    modelLevelAPI = false;
end
%--------------------------------------------------------------------------
%% Add commands to create a new model.
fprintf(fid,'%s\n',['modelName = ''' systemName '_API'';']);
fprintf(fid,'%s\n','new_system(modelName);');

%--------------------------------------------------------------------------
%% Get all the blocks of a given System and run iteratively add API commands.
modelBlocks = find_system(systemName,'LookUnderMasks','on');
fprintf(fid,'%s\n','% Add Blocks and set the block position. ');
for ii = 2:numel(modelBlocks)
    % Get the positions of the blocks.
    % Check library reference.
    if ~(isempty(get_param(modelBlocks{ii},'ReferenceBlock')))
        srcPath = get_param(modelBlocks{ii},'ReferenceBlock');
        destPath = strrep(modelBlocks{ii},systemName,'');
        destPath = strrep(destPath,char(10),[''' char(10) ''']);
        fprintf(fid,'%s\n',['add_block([''' srcPath '''],[modelName,''' destPath ''']);']);
        
    elseif strcmp(get_param(modelBlocks{ii},'BlockType'),'ModelReference')
        % Check Model reference.
        srcPath = getSimulinkPath('ModelReference');
        srcPath = strrep(srcPath,char(10),[''' char(10) ''']);
        destPath = strrep(modelBlocks{ii},systemName,'');
        destPath = strrep(destPath,char(10),[''' char(10) ''']);
        mdlRef = get_param(modelBlocks{ii},'ModelName');
        fprintf(fid,'%s\n',['add_block([''' srcPath '''],[modelName,''' destPath ''']);']);
        fprintf(fid,'%s\n',['set_param([modelName,''' destPath '''],''ModelName'',''' mdlRef ''');']);
        
    else
        % Get sourcePath of the blocks using getSimulinkPath() function.
        srcPath = getSimulinkPath(get_param(modelBlocks{ii},'BlockType'));
        srcPath = strrep(srcPath,char(10),[''' char(10) ''']);
        destPath = strrep(modelBlocks{ii},systemName,'');
        destPath = strrep(destPath,char(10),[''' char(10) ''']);
        blkType = get_param(modelBlocks{ii},'BlockType');
        dialParams = get_param(modelBlocks{ii},'DialogParameters');
        if ~ isempty(dialParams)
            dialProps = fieldnames(dialParams);
        end
        blkParams = get_param(modelBlocks{ii},'objectParameters');
        blkProps = fieldnames(blkParams);
        if strcmp(blkType,'SubSystem')
            % To make the getSimulinkPath to locate the correct subsystem
            % path.
            blkType = 'Subsystem';
        end
        if ~strcmp(blkType,'Subsystem')
            % API commands for the blocks.
            fprintf(fid,'%s\n',['add_block([''' srcPath '''],[modelName,''' destPath ''']);']);
        else
            % For Masked sub systems.
            if strcmp(get_param(modelBlocks{ii},'mask'),'on')
                srcPath = getSimulinkPath(blkType);
                srcPath = strrep(srcPath,char(10),[''' char(10) ''']);
                fprintf(fid,'%s\n',['add_block([''' srcPath '''],[modelName,''' destPath ''']);']);
                fprintf(fid,'%s\n',['delete_line([modelName,''' destPath '''],''In1/1'',''Out1/1'');']);
                fprintf(fid,'%s\n',['delete_block([modelName,''' destPath '/In1'']);']);
                fprintf(fid,'%s\n',['delete_block([modelName,''' destPath '/Out1'']);']);
                if isfield(get_param(modelBlocks{ii},'ObjectParameters'),'MaskObject')
                    % Latest version.
                    generateMaskAPI(modelBlocks{ii},destPath,fid);
                else
                    % Older version.
                    fprintf(fid,'%s\n',['set_param([modelName,''' destPath '''],''Mask'',''on'')']);
                end
            else
                % For subSystems.
                srcPath = getSimulinkPath(blkType);
                srcPath = strrep(srcPath,char(10),[''' char(10) ''']);
                fprintf(fid,'%s\n',['add_block([''' srcPath '''],[modelName,''' destPath ''']);']);
                fprintf(fid,'%s\n',['delete_line([modelName,''' destPath '''],''In1/1'',''Out1/1'');']);
                fprintf(fid,'%s\n',['delete_block([modelName,''' destPath '/In1'']);']);
                fprintf(fid,'%s\n',['delete_block([modelName,''' destPath '/Out1'']);']);
            end
        end
        
        %------------------------------------------------------------------
        % Set dialog parametes.
        for jj = 1:numel(dialProps)
            try
                propValue = get_param(modelBlocks{ii},dialProps{jj});
                refValue = get_param(getSimulinkPath(blkType),dialProps{jj});
            catch exceptionObj
                if (strcmp(exceptionObj.identifier,'Simulink:Commands:ParamUnknown'))
                    refValue = '';
                    continue;
                else
                    rethrow(exceptionObj);
                end
            end
            res = isequal(propValue,refValue);
            if (~(res) && ~strcmp(dialProps{jj},'IsSubsystemVirtual'))
                if isnumeric(get_param(modelBlocks{ii},dialProps{jj}))
                    fprintf(fid,'%s\n',['set_param([modelName,''' destPath '''],''' dialProps{jj} ''',[' num2str(get_param(modelBlocks{ii},dialProps{jj})) ']);']);
                elseif ~ isstruct(dialProps{jj})
                    ischar(get_param(modelBlocks{ii},dialProps{jj}));
                    outString = get_param(modelBlocks{ii},dialProps{jj});
                    outString = strrep(outString, '''' , '''''');
                    outString = strrep(outString,'char(10)',[''' char(10) ''']);
                    fprintf(fid,'%s\n',['set_param([modelName,''' destPath '''],''' dialProps{jj} ''',''' outString ''');']);
                end
            end
        end
    end
    
    %------------------------------------------------------------------
    % Block Properties.
    for jj = 1:numel(blkProps)
        % Check the read-only attribute
        if ~(strcmp(blkParams.(blkProps{jj}).Attributes{1},'read-only'))
            try
                propValue = get_param(modelBlocks{ii},blkProps{jj});
                refValue = get_param(getSimulinkPath(blkType),blkProps{jj});
            catch exceptionObj
                if (strcmp(exceptionObj.identifier,'Simulink:Commands:ParamUnknown'))
                else
                    rethrow(exceptionObj);
                end
            end
            res = isequal(propValue,refValue);
            if (~(res) && ~strcmp(blkProps{jj},'CurrentBlock'))
                if isnumeric(get_param(modelBlocks{ii},blkProps{jj}))
                    fprintf(fid,'%s\n',['set_param([modelName,''' destPath '''],''' blkProps{jj} ''',[' num2str(get_param(modelBlocks{ii},blkProps{jj})) ']);']);
                elseif isstr(get_param(modelBlocks{ii},blkProps{jj}))
                    %if(strcmp(blkProps{jj},'MaskDisplay'))
                    outString = get_param(modelBlocks{ii},blkProps{jj});
                    outString = strrep(outString, '''' , '''''');
                    fprintf(fid,'%s\n',['set_param([modelName,''' destPath '''],''' blkProps{jj} ''',[''' strrep(outString,char(10),[''' char(10) ''']) ''']);' ]);
                else
                    % TODO : handle the cell array and structure.
                end
            end
        end
    end
end
%----------------------------------------------------------------------
%% Set Signal Properties.
portHandles = get_param(modelBlocks{ii},'PortHandles');
outProps = get_param(portHandles.Outport,'ObjectParameters');
if ~(isempty(outProps))
    blkType = get_param(modelBlocks{ii},'BlockType');
    refPortHandles = get_param(getSimulinkPath(blkType),'PortHandles');
    refOutProps = get_param(refPortHandles.Outport,'ObjectParameters');
    outFields = fieldnames(outProps);
    destPath = strrep(modelBlocks{ii},systemName,'');
    destPath = strrep(destPath,char(10),[''' char(10) ''']);
    fprintf(fid,'%s\n',['portHandles' num2str(ii-1) ' = get_param([modelName, ''' destPath '''],''PortHandles'');']);
    for jj = 1:numel(outFields)
        if ~(strcmp(outProps.(outFields{jj}).Attributes{1},'read-only'))
            if ~(strcmp(outFields{jj},'SignalObject') || strcmp(outFields{jj},'PropagatedSignals'))
                srcValue = get_param(portHandles.Outport,outFields{jj});
                refValue = get_param(refPortHandles.Outport,outFields{jj});
                if ~strcmp(srcValue,refValue)
                    if isnumeric(get_param(portHandles.Outport,outFields{jj}))
                        fprintf(fid,'%s\n',['set_param(portHandles' num2str(ii-1) '.Outport,''' outFields{jj} ''',''' mat2str(get_param(portHandles.Outport,outFields{jj})) ''');']);
                    else
                        fprintf(fid,'%s\n',['set_param(portHandles' num2str(ii-1) '.Outport,''' outFields{jj} ''',''' get_param(portHandles.Outport,outFields{jj}) ''');']);
                    end
                end
            end
        end
    end
end
%--------------------------------------------------------------------------
%% Draw Lines.
fprintf(fid,'%s\n','% Adding Lines.');
lineH = find_system(systemName,'findAll','on','LookUnderMasks','on','type','line');
for ii = 1:numel(lineH)
    srcBlkHandle = get_param(lineH(ii),'SrcBlockHandle');
    linePath = get_param(srcBlkHandle,'Parent');
    linePath = strrep(linePath,systemName,'');
    linePath = strrep(linePath,char(10),[''' char(10) ''']);
    linePts = get_param(lineH(ii),'Points');
    fprintf(fid,'%s\n',['add_line([modelName,''' linePath '''],' mat2str(linePts) ');']);
end

%--------------------------------------------------------------------------
%% Annotations
fprintf(fid,'%s\n','% Adding Annotations.');
antn = find_system(systemName,'FindAll','on','type','annotation');
dummyAntn = Simulink.Annotation([systemName '/dummy']);
dummyAntnProps = get(dummyAntn);
dummyAntnFields = fieldnames(dummyAntnProps);
for ii = 1:numel(antn)
    antnProps = get(antn(ii));
    antnPath = antnProps.Path;
    antnPath = strrep(antnPath,systemName,'');
    antnFields = fieldnames(antnProps);
    fprintf(fid,'%s\n',['antn' num2str(ii) ' = Simulink.Annotation([modelName ''' antnPath '/' strrep(antnProps.Text,char(10),[''' char(10) ''']) ''']);']);
    for jj = 1:numel(antnFields)
        if ~(strcmp(get(antn(ii),antnFields{jj}),get(dummyAntn,dummyAntnFields{jj})))
            if isnumeric(get(antn(ii),antnFields{jj})) && ~strcmp(antnFields{jj},'Handle')
                fprintf(fid,'%s\n',['set(antn' num2str(ii) '(1),''' antnFields{jj} ''',[' num2str(get(antn(ii),antnFields{jj})) ']);']);
            elseif isstring(get(antn(ii),antnFields{jj}))
                fprintf(fid,'%s\n',['set(antn((1)' num2str(ii) '),''' antnFields{jj} ''',''' strrep(get(antn(ii),antnFields{jj}),char(10),[''' char(10) ''']) ''');']);
            end
        end
    end
end
delete(dummyAntn);
%--------------------------------------------------------------------------
%% If the API is required for a subsystem level, then there is no need of model parameters and properties.
if ~modelLevelAPI
    fprintf(fid,'%s\n','open_system(modelName);');
    return;
end
%--------------------------------------------------------------------------
%% Model Properties.
refModelPath = tempname;
[path,refModelFile,ext] = fileparts(refModelPath);
refModel = new_system(refModelFile);
mdlProps = get_param(systemName,'objectParameters');
refMdlProps = get_param(refModel,'objectParameters');
mdlFields = fieldnames(mdlProps);
refMdlFields = fieldnames(refMdlProps);
for ii = 2: numel(mdlFields)
    %fprintf(fid,'%s\n',ii);
    if (~(strcmp(mdlProps.(mdlFields{ii}).Attributes{1},'read-only'))) && (~(strcmp(mdlProps.(mdlFields{ii}).Attributes{1},'write-only'))) && (~(strcmp(mdlProps.(mdlFields{ii}).Attributes{1},'dont-eval'))) && ~(strcmp(mdlFields{ii},'ProdEndianess')) && ~(strcmp(mdlFields{ii},'RTWOptions'))
        if ~(strcmp(get_param(systemName,mdlFields{ii}),get_param(refModel,refMdlFields{ii})))
            if (isstr(get_param(systemName,mdlFields{ii})))
                fprintf(fid,'%s\n',['set_param(modelName,''' mdlFields{ii} ''',[''' strrep(strrep(get_param(systemName, mdlFields{ii}),'''',''''''),char(10),[''' char(10) '''])  ''']);' ]);
            elseif (iscell(get_param(systemName,mdlFields{ii})))
                value = get_param(systemName, mdlFields{ii});
                fprintf(fid,'%s\n',['set_param(modelName,''' mdlFields{ii} ''',''' value{1}  ''');' ]);
            end
        end
    end
end
bdclose(refModelFile);
%--------------------------------------------------------------------------
%% Model Configuration Parameters.
% Get the default configuration data.
tempConfig = Simulink.ConfigSet;

% Use a temporary file to store the model configuration parameters.
tempConfigPath = tempname;
[path,tempConfigFile,ext] = fileparts(tempConfigPath);
tempConfigFile = [tempConfigFile '.m'];
Simulink.BlockDiagram.saveActiveConfigSet(systemName, tempConfigFile);

% Read line by line and parse the string to get the parameter and value.
% Print the parameter only if the value is differing with the default
% value.
fileId = fopen(tempConfigFile);
fileLine = fgetl(fileId);
startMatch = true;
while ischar(fileLine)
    previousLine = fileLine;
    fileLine = fgetl(fileId);
    if ~ischar(fileLine)
        break;
    end
    setParamMatch = regexp(fileLine,'^cs\.set_param\(');
    switchTargetMatch = regexp(fileLine,'^cs\.switchTarget\(');
    if ~isempty(switchTargetMatch)
        % TODO:
        continue;
    end
    if ~isempty(setParamMatch)
        if startMatch
            fprintf(fid,'%s\n',strrep(previousLine,char(10),[''' char(10) ''']));
        end
        startMatch = false;
        paramData = regexp(fileLine,'cs\.set_param\(\''(?<parameter>[\w]+)\''\,\s+\''(?<value>[\.\,\*\\\%\(\)\s\-\w]*)\''\)\;\s+(?<comment>.*)','names');
        if ~isempty(paramData)
            try
                paramValue = tempConfig.get_param(paramData.parameter);
            catch exceptionObj
                if (exceptionObj.identifier == 'Simulink:ConfigSet:IgnoredParam')
                else
                    rethrow(exceptionObj);
                end
            end
            % Process only if the values are not same.
            if ~isequal(paramData.value,paramValue)
                fprintf(fid,'%s\n',strrep(regexprep(fileLine,'cs\.set_param\(','set_param( modelName,'),char(10),[''' char(10) ''']));
            end
        else
            % Not able to handle with the regexp. Hence use it as it is.
            fprintf(fid,'%s\n',strrep(regexprep(fileLine,'cs\.set_param\(','set_param(modelName,'),char(10),[''' char(10) ''']));
        end
    elseif ~startMatch
        % Lines that didn't have cs.set_param.
        fprintf(fid,'%s\n',strrep(fileLine,char(10),[''' char(10) ''']));
    end
end
% Close and delete the file.
fclose(fileId);
delete(tempConfigFile);

%--------------------------------------------------------------------------
fprintf(fid,'%s\n','open_system(modelName);');
if nargin>1
    fclose(fid);
end

end
