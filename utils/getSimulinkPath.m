function simulinkPath = getSimulinkPath(blockDetail)
% Helps to find the referred block path from the Custom or Simulink library
% for the given block.
% It uses following approach in finding the path.
% 1. Checks if blockDetail has a '/' in it. If it has, it recognizes it as
% the block path and opens the relevant library and locates the block.
% 2. If it is not found, then searches in the standard Simulink
% library.
% 3. Else returns empty.
%
%  Sample:
% >> simulinkPath = getSimulinkPath('In1')
% simulinkPath =
% simulink/Commonly
% Used Blocks/In1
%

simulinkPath = '';
% Check if the complete block path specified.
if (~isempty(strfind(blockDetail, '/')))
    libraryName = strtok(blockDetail, '/');
    try
        load_system(libraryName);
        find_system(blockDetail);
    catch
        % If anything is wrong then simply return empty.
        return;
    end
    simulinkPath = blockDetail;
end

% If it is not found, look for the block in simulink - search for type
% first.
if (isempty(simulinkPath))
    simLibrary = 'simulink';
    load_system(simLibrary);
    % Match with the Simulink blocktype - if the blockDetail is not
    % s-function!
    if (~strcmpi(blockDetail, 'S-function'))
        allBlocksType = find_system(simLibrary,'BlockType',blockDetail);
        if (~isempty(allBlocksType))
            simulinkPath = allBlocksType{1};
        end
    end
    
    % Search the block name in the Simulink library and then with search
    % using regexp.
    if (isempty(simulinkPath))
        allBlocks = find_system(simLibrary,'Name',blockDetail);
        if (~isempty(allBlocks))
            simulinkPath = allBlocks{1};
        end
        
        % RegExp is being used for blocks with space characters in their
        % names.
        if (isempty(simulinkPath))
            blockDetail = strrep(blockDetail,' ','\s*');
            allBlocks = find_system(simLibrary,'CaseSensitive','off','RegExp','on','Name',blockDetail);
            if (~isempty(allBlocks))
                simulinkPath = allBlocks{1};
            end
        end
    end
end

end
