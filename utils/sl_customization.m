function sl_customization(cm)
% Menu item for Simulink API generation under File menu and also in block
% context menu

%% Register custom Contextmenu function
cm.addCustomMenuFcn('Simulink:FileMenu', @getMyMenuItems);
cm.addCustomMenuFcn('Simulink:PreContextMenu', @getMyContextMenuItems);

end

%% Define the custom menu function.
function schemaFcns = getMyMenuItems(callbackInfo)  %#ok<*INUSD>
% Define the Item in Menu
schemaFcns = {@getMenu};
end
%% Define the custom context menu function.
function schemaFcns = getMyContextMenuItems(callbackInfo)  %#ok<*INUSD>
% Define the Item in Menu
schemaFcns = {@getContextMenu};
end

function schema = getMenu(callbackInfo)
schema = sl_action_schema;
schema.label = 'Generate Simulink API';
schema.callback = @menu_Callback;
end

function schema = getContextMenu(callbackInfo)
schema = sl_action_schema;
schema.label = 'Generate Simulink API';
schema.callback = @contextMenu_Callback;
end

function menu_Callback(callbackInfo)
generateSimulinkAPI(bdroot(gcs));
end

function contextMenu_Callback(callbackInfo)
currentBlock = gcb;
blockType = get_param(currentBlock,'BlockType');
if strcmpi(blockType,'Subsystem')
    generateSimulinkAPI(currentBlock);
else
    generateSimulinkAPI(gcs);
end
end