function generateMaskAPI(blockHandle,destPath,fid)
% Helps to get the API code for mask dialog.

maskH = Simulink.Mask.get(blockHandle);
fprintf(fid,'%s\n',['maskObj = Simulink.Mask.create([modelName,''' destPath ''']);']);
maskFields = fieldnames(maskH);
for mm = 1:numel(maskFields)-1
    if strcmp(maskFields{mm},'Parameters')
        % To handle mask dialog parameters.
        maskParams = fieldnames(maskH.Parameters);
        for jj = 1:numel(maskH.Parameters)
            fprintf(fid,'%s\n','maskObj.addParameter();');
            for kk = 1:numel(maskParams)
                if isnumeric(maskH.Parameters(jj).(maskParams{kk}))
                    fprintf(fid,'%s\n',['maskObj.Parameters(' num2str(jj) ').' maskParams{kk} '= [' num2str(maskH.Parameters(jj).(maskParams{kk})) '];' ]);
                elseif isstr(maskH.Parameters(jj).(maskParams{kk}))
                    outString = strrep(maskH.Parameters(jj).(maskParams{kk}),'''' , '''''');
                    outString = strrep(outString,char(10),[''' char(10) ''']);
                    fprintf(fid,'%s\n',['maskObj.Parameters(' num2str(jj) ').' maskParams{kk} '=''' outString ''';' ]);
                elseif isempty(maskH.Parameters(jj).(maskParams{kk}))
                    % Empty property.
                else
                    % TODO: Have to handle the cell array.
                    fprintf(fid,'%s\n',['maskObj.Parameters(' num2str(jj) ').' maskParams{kk} '='''  ''';' ]);
                end
            end
        end
    else
        outString = strrep(maskH.(maskFields{mm}),'''' , '''''');
        outString = strrep(outString,char(10),[''' char(10) ''']);
        if isstr(outString)
            fprintf(fid,'%s\n',['maskObj.' maskFields{mm} ' = [''' outString '''];' ]);
        else
            fprintf(fid,'%s\n',['maskObj.' maskFields{mm} ' = ''' outString ''';' ]);
        end
    end
end

% To handle mask dialog controls.
dlgControls = maskH.getDialogControls;
generateNestedDialogAPI(maskH,dlgControls,fid);

end
%--------------------------------------------------------------------------
function generateNestedDialogAPI(parentObj,dlgControls,fid)
% Recursive function to generate API for mask dialog controls.

for ii = 1:length(dlgControls)
    controlProperties = properties(dlgControls(ii));
    controlType = class(dlgControls(ii));
    if isempty(strfind(controlType,'.parameter'))
        % Dialog control
        controlType = lower(strrep(controlType,'Simulink.dialog.',''));
        if strcmpi(class(parentObj),'Simulink.Mask')
            fprintf(fid,'%s\n',[dlgControls(ii).Name ' = maskObj.getDialogControl(''' dlgControls(ii).Name ''');']);
            fprintf(fid,'%s\n',['if isempty(' dlgControls(ii).Name ')']);
            fprintf(fid,'%s\n',[dlgControls(ii).Name ' = maskObj.addDialogControl(''' controlType ''',''' dlgControls(ii).Name ''');']);
            fprintf(fid,'%s\n','end');
        else
            fprintf(fid,'%s\n',[dlgControls(ii).Name ' = ' parentObj.Name '.getDialogControl(''' dlgControls(ii).Name ''');']);
            fprintf(fid,'%s\n',['if isempty(' dlgControls(ii).Name ')']);
            fprintf(fid,'%s\n',[dlgControls(ii).Name ' = ' parentObj.Name '.addDialogControl(''' controlType ''',''' dlgControls(ii).Name ''');']);
            fprintf(fid,'%s\n','end');
        end
        childDlgControls = [];
        for jj = 1:length(controlProperties)
            if strcmpi(controlProperties{jj},'Name')
                % Name is already set.
            elseif strcmpi(controlProperties{jj},'DialogControls')
                childDlgControls = dlgControls(ii).DialogControls;
            else
                outString = strrep(dlgControls(ii).(controlProperties{jj}),'''' , '''''');
                outString = strrep(outString,char(10),[''' char(10) ''']);
                fprintf(fid,'%s\n',[dlgControls(ii).Name '.' controlProperties{jj} '=''' outString ''';' ]);
            end
        end
        if ~isempty(childDlgControls)
            generateNestedDialogAPI(dlgControls(ii),childDlgControls,fid);
        end
    else
        % Parameter under the mask control.
        fprintf(fid,'%s\n',['parameterObj = maskObj.getDialogControl(''' dlgControls(ii).Name ''');']);
        if strcmpi(class(parentObj),'Simulink.Mask')
            fprintf(fid,'%s\n','parameterObj.moveTo(maskObj);');
        else
            fprintf(fid,'%s\n',['parameterObj.moveTo(' parentObj.Name ');']);
        end
    end
end

end