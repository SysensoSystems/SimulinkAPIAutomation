function generateModelConfigParameters(modelName)
% Gets the model configuration parameters that are changed from its default
% value.

% Get the default configuration data.
tempConfig = Simulink.ConfigSet;

% Use a temporary file to store the model configuration parameters.
tempConfigPath = tempname;
[path,tempConfigFile,ext] = fileparts(tempConfigPath);
tempConfigFile = [tempConfigFile '.m'];
Simulink.BlockDiagram.saveActiveConfigSet(modelName, tempConfigFile);

% Read line by line and parse the string to ger the parameter and value.
% Print the parameter only if the value is differing with the default
% value.
fid = fopen(tempConfigFile);
fileLine = fgetl(fid);
startMatch = true;
while ischar(fileLine)
    previousLine = fileLine;
    fileLine = fgetl(fid);
    if ~ischar(fileLine)
        break;
    end
    setParamMatch = regexp(fileLine,'^cs\.set_param\(');
    switchTargetMatch = regexp(fileLine,'^cs\.switchTarget\(');
    if ~isempty(setParamMatch)
        if startMatch
            disp(previousLine);
        end
        startMatch = false;
        paramData = regexp(fileLine,'cs\.set_param\(\''(?<parameter>[\w]+)\''\,\s+\''(?<value>[\.\,\*\\\%\(\)\s\-\w]*)\''\)\;\s+(?<comment>.*)','names');
        if ~isempty(paramData)
            paramValue = tempConfig.get_param(paramData.parameter);
            % Process only if the values are not same.
            if ~isequal(paramData.value,paramValue)
                disp(regexprep(fileLine,'cs\.set_param\(',['set_param(''' modelName ''', ']));
            end
        else
            % Not able to handle with the regexp. Hence use it as it is.
            disp(regexprep(fileLine,'cs\.set_param\(',['set_param(''' modelName ''', ']));
        end
    elseif ~startMatch
        % Lines that didn't have cs.set_param.
        disp(fileLine);
    elseif ~isempty(switchTargetMatch)
        % TODO:
    end
end
% Close and delete the file.
fclose(fid);
delete(tempConfigFile);

end